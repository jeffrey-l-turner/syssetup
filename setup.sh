#!/bin/bash
# Script to setup headless node system as general shell 
# on *nix 
#########################################################
#   Script Requirements
#
#   Programs:
#     curl
#     sed
#     tail
#     basename
#     date
#     rm
#     mv
#     jwc
#     cat
#     wget
#     echo
#     git
#     xcode-select # if on MacOS
#########################################################
 
#########################################################
# setup some useful error handling functions
#########################################################
 
# shellcheck disable=SC2120 
usage() {
 	echo "$(basename "$0")": ERROR: "$*" 1>&2
        echo usage: './'"$(basename "$0")" ' (for interactive mode) '  1>&2
        echo "cat $(basename "$0") | /bin/bash <or other sh-compatible shell> (for non-interactive mode)" 1>&2
 	exit 1
}
 
cleanup() {
    datetime=$(date +%Y%m%d%H%M%S)
    echo -e "cleaning up... at: ${datetime}"
}

error() {
 	cleanup
 	echo "$(basename "$0")": ERROR: "$*" 1>&2
 	echo "shuting down... internal error or unable to connect to Internet" 1>&2
 	exit 2
}

interrupt () {
 	cleanup
 	echo "$(basename "$0")": INTERRUPTED: "$*" 1>&2
 	echo "Cleaning up... removed files" 1>&2
 	exit 2
}
 
trap error TERM 
trap interrupt INT  
 
if  [ "$#" -ne 0 ]; then
# shellcheck disable=SC2119 
    usage
fi

# Version of Node to use:
nvmuse="v8.10"  # note: v + version number is required for pathing on nvm usage
# binary of node to use on Windows/Cygwin
winNode="http://nodejs.org/dist/${nvmuse}/x64/node-${nvmuse}-x64.msi"

# location of dotfiles on Git
# not using git ssh key to insure easy copy without adding key
# originally: gitdotfiles="git@github.com:jeffrey-l-turner/dotfiles.git"
# change ~/dotfiles/.git/config to above url if pushing/pulling from that repo
gitdotfiles="https://github.com/jeffrey-l-turner/dotfiles.git"

# location of vundle on Git
vundle="https://github.com/gmarik/vundle.git"

# location of pathogent specific plugins (using generally) 
commandt="git://git.wincent.com/command-t.git" 
#libsyn="git://github.com/othree/javascript-libraries-syntax.vim.git"
 
lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

if [ -f "$(which git)" ]; then
    gitInstalled="true"
else
    gitInstalled="false"
    echo "Git not installed..."
fi

installGit() {
    if [ "$gitInstalled" == "false" ]; then
       if [ "${OS}" == "mac" ]; then
          $AppInstall install git
       elif [ "${OS}" == "cygwin" ]; then
          echo "installing git via Cygwin"
          $AppInstall install git
       else
          $AppInstall install -y git-core 
       fi
    fi
    gitInstalled="true"
}

# git pull and install dotfiles if not already cloned previously- modified as function for use with adding ssh keys
dotFilesCloned="false"
cloneDotFiles(){
    if [ "$dotFilesCloned" == "false" ]; then
        cd "$HOME" || error "unable to cd $HOME"
        installGit
        if [ -d ./dotfiles/ ]; then
            rm -rf dotfiles.old
            mv dotfiles dotfiles.old
        fi
        if [ -d .emacs.d/ ]; then
            mv .emacs.d .emacs.d~
        fi
        git clone $gitdotfiles
        if [ "${OS}" != "mac" ]; then
            rm -rf "$HOME/dotfiles/term_settings"
        fi
    fi
    dotFilesCloned="true"
}

nvmInstalled="false"
installNVM (){
    set +o errexit # nvm shell scripts have a habit of return non-zero error codes upon success
    if [ "$nvmInstalled" = "false" ]; then
        # Install nvm: node-version manager
        # https://github.com/creationix/nvm
        # nvm locations have frequently changed
        # using clone and manual installation:
        if [ ! -d ~/.nvm/ ]; then
            # Load nvm and install latest production node
            if ! git clone git://github.com/creationix/nvm.git "$HOME/.nvm" ; then 
               echo "nvm installation command failed"; 
               exit 1; 
            fi
        fi 
        if [ "${OS}" = "mac" ]; then
            $AppInstall install openssl
        fi
        # shellcheck disable=SC1090
        . "$HOME/.nvm/nvm.sh"
        nvm install $nvmuse
        nvm use $nvmuse
        nvm alias default $nvmuse
    fi 
    nvmInstalled="true"
    set -o errexit 
}

bashCompletion="false"
installBashCompletion (){
    if [ "$bashCompletion" == "false" ]; then
        if [ "${OS}" != "mac" ]; then
            # set note on bash completion in ~/.bashrc_custom
            echo "Installing git and bash-completion via brew since Apple's"
            echo "git has compatibility problems with git-flow-completion"
            $AppInstall install git-flow-completion 
            if ! $AppInstall install bash-completion; then
                echo '# setup bash completion setup for shell' >> "$HOME/.bashrc_custom"
            else
                echo '# setup bash completion not setup; must manually enable' >> "$HOME/.bashrc_custom"
            fi
        fi
        if [ "${OS}" == "cygwin" ]; then
            # Download and place git-flow-completion.bash in %CYGWIN_INSTALLATION_DIR%\etc\bash_completion.d
            # Rename it to git-flow
            echo "bash completion not installaed on Cygwin"
        fi
        if [ "${OS}" == "mac" ]; then
            # shellcheck disable=SC2016,SC2129
            echo 'if [ -f `brew --prefix`/etc/bash_completion ]; then' >> "$HOME/.bashrc_custom"
            # shellcheck disable=SC2016,SC2129
            echo '       . `brew --prefix`/etc/bash_completion' >> "$HOME/.bashrc_custom"
            echo 'fi' >> "$HOME/.bashrc_custom"
        fi
    fi
    bashCompletion="true"
}
 
installShellCheck (){
    $AppInstall install shellcheck
}


if which node > /dev/null 2>&1 ; then # for Cygwin compatibility 
    nodeInstalled="true"
else
    nodeInstalled="false"
fi

# Global installation for node:
nodeGlobalInstall() {
    if [ "${OS}" == "cygwin" ]; then
      wget $winNode
      msi=$(echo $winNode | sed -e 's/.*\///')
      mv "${msi}" /tmp
      echo "running msiexec.exe to install: ${msi}"
      # shellcheck disable=SC2046,SC2006,SC2086
      run msiexec.exe /i `cygpath -d /tmp/$msi` 
      echo "restart system prior to installing rest of $0"
      #rm -f ${msi} 
    else
      echo -e  "copying node files for version $nvmuse... enter sudo password if prompted"
      echo -e  "enter sudo password if prompted"
      echo -e " "
      if [ "${OS}" == "mac" ]; then # globally install node for Mac users via Homebrew
          installNVM
      else
          installNVM
          n=$(which node);n=${n%/bin/node}; chmod -R 755 "$n/bin/*"; sudo cp -r "$n/{bin,lib,share}" /usr/local
      fi
    fi
}


####################################################################
# Get System Info
####################################################################
shootProfile(){
    OS=$(lowercase "$(uname)")
    KERNEL=$(uname -r)
    MACH=$(uname -m)

    if [ "${OS}" == "darwin" ]; then
        OS="mac"
        REV=$(uname -r)
        PSEUDONAME="Darwin"
        DistroBasedOn='BSD'
        AppInstall="brew "
        DIST="Apple OS X"
    elif [ "$(echo "${OS}" | cut -b 1-6)" == "cygwin" ]; then
        OS="cygwin"
        DIST="Windows POSIX"
        REV=$(uname -r)
        PSEUDONAME=$(uname)
        DistroBasedOn='POSIX'
        AppInstall="apt-cyg "
        gitInstalled="true"
    else
        OS=$(uname)

        if [ "${OS}" = "Linux" ]; then
            if [ -f /etc/centos-release ]; then
                DistroBasedOn='redhat'
                DIST=$(sed 's/ *Linux.*//I' /etc/centos-release)
                PSEUDONAME=$(sed s/.*\(// /etc/centos-release | sed s/\)//)
                REV=$(sed 's/.*release\ //' /etc/centos-release | sed s/\ .*//)
                AppInstall="sudo yum "
            elif [ -f /etc/redhat-release ]; then
                DistroBasedOn='redhat'
                DIST=$(sed 's/\ release.*//' /etc/redhat-release)
                PSEUDONAME=$(sed s/.*\(// /etc/redhat-release | sed s/\)//)
                REV=$(sed 's/.*release\ //' /etc/redhat-release | sed s/\ .*//)
                AppInstall="sudo yum "
            elif [ -f /etc/SuSE-release ]; then
                DistroBasedOn='SuSe'
                PSEUDONAME=$(tr "\n" ' ' </etc/SuSE-release | sed s/VERSION.*//)
                REV=$(tr "\n" ' ' < /etc/SuSE-release | sed s/.*=\ //)
                AppInstall="exit 2"
            elif [ -f /etc/mandrake-release ]; then
                DistroBasedOn='Mandrake'
                PSEUDONAME=$(sed 's/.*\(//' /etc/mandrake-release | sed s/\)//)
                REV=$(sed 's/.*release\ //' /etc/mandrake-release | sed s/\ .*//)
                AppInstall="exit 2"
            elif [ -f /etc/debian_version ]; then
                DistroBasedOn='Debian'
                if [ -f /etc/lsb-release ]; then
                        DIST=$(grep '^DISTRIB_ID' /etc/lsb-release | awk -F=  '{ print $2 }')
                            PSEUDONAME=$(grep '^DISTRIB_CODENAME' /etc/lsb-release | awk -F=  '{ print $2 }')
                            REV=$(grep '^DISTRIB_RELEASE' /etc/lsb-release | awk -F=  '{ print $2 }')
                elif [ -f /etc/os-release ]; then
                    DistroBasedOn='Debian'
                    DIST=$(grep '^PRETTY_NAME' /etc/os-release | awk -F=  '{ print $2 }')
                    REV=$(grep '^VERSION_ID' /etc/os-release | awk -F=  '{ print $2 }' | sed 's/\"//g')
                    PSEUDONAME=$(grep '^PRETTY_NAME' /etc/os-release | awk -F=  '{ print $2 }' | awk -F'\(' '{ print $2 }' | sed 's/)\"//')
                fi
                AppInstall="sudo apt-get "
            elif [ -f /etc/UnitedLinux-release ]; then
                DIST="${DIST}[$(tr "\n" ' ' < /etc/UnitedLinux-release  | sed s/VERSION.*//)]"
            fi

            if [ "${DIST}" = "" ] && [ -f /etc/os-release ]; then # catch all for Fedora based... incl. amazon
                DIST="$(grep -i ^NAME /etc/os-release | sed  s/NAME=//i | sed s/\"//g )"
                REV="$(grep -i '^VERSION=' /etc/os-release | sed  s/version=//i | sed s/\"//g )"
                DistroBasedOn='RHEL Fedora'
                PSEUDONAME="$(grep -i '^ID=' /etc/os-release | sed  s/id=//i | sed s/\"//g )"
                AppInstall="sudo yum "
            fi

            DistroBasedOn=$(lowercase "${DistroBasedOn}")
            OS=$(lowercase "$OS")
        fi

    fi 
    readonly OS
    readonly DIST
    readonly DistroBasedOn
    readonly PSEUDONAME
    readonly REV
    readonly KERNEL
    readonly MACH
}

if [ "${gitInstalled}" != "true" ] ; then 
        installGit;
fi

# Setup for config files using ssh:
if [ ! -d "$HOME/.ssh/" ]; then
    mkdir "$HOME/.ssh"
fi 
if [ "${OS}" == "mac" ]; then
    cp "$HOME/.ssh/config" "$HOME/.ssh/" 
else
    touch "$HOME/.ssh/config" 
    chmod 600 "$HOME/.ssh/config"
fi

# These are functions to setup ssh keys for Heroku and GitHub:
# The keys must still be registered with the respective accounts by the user
herokuKey="false"
genHeroku(){
    echo -e '\t Generating Heroku Key (~/.ssh/heroku-rsa)'
    echo "Enter email address for Heroku key:"
    read -r email;
    ssh-keygen -t rsa -C "$email" -f "$HOME/.ssh/heroku-rsa"
    herokuKey="true"
    cloneDotFiles;
    cat "$HOME/dotfiles/ssh-config-heroku" >> "$HOME/.ssh/config"
    echo "Note: you must still upload your key to your Heroku account!"
}

githubKey="false"
genGitHub(){
    echo -e '\t Generating GitHub Key (~/.ssh/github-rsa)'
    echo "Enter email address for GitHub key:"
    read -r email;
    ssh-keygen -t rsa -C "$email"  -f "$HOME/.ssh/github-rsa"
    githubKey="true"
    cloneDotFiles;
    cat "$HOME/dotfiles/ssh-config-github" >> "$HOME/.ssh/config"
    echo "Note: you must still upload your key to your GitHub profile!"
}

setFlags(){
    readonly "githubKey"
    readonly "herokuKey"
    readonly "editorInstall" 
}

# These are functions to setup to toggle vim and emacs installation
# vim will be installed along with vundle and the refactor colorscheme (via .vimrc) by default
editorInstall=vim
toggleVimEmacs(){
        if [ "${editorInstall}" == "vim" ] ; then
            editorInstall="emacs"
        else
            editorInstall="vim"
        fi  

}

# Toggle installation of MongoDB
installMongo="false";

InstallMongo(){
    if [ "${installMongo}" == "false" ]; then
         installMongo="true"
     else
         installMongo="false"
    fi
}

# Load menu in interactive mode
shootProfile

# If using Mac OS, then check if xcode is installed, then install brew & ctags
if [ "${OS}" == "mac" ]; then
    if $(which xcode-select) -p ; then
        echo "xcode version: $(xcode-select --version) installed"
    else
        echo "xcode command line tools are not installed..." 
        echo "please install xcode before proceeding" 
        echo " (see:http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12)"
        echo ""
        echo "Attempting to install xcode tools... please follow instructions to install and re-run $0"
        $(which xcode-select) --install
        echo "Make sure your xcode tools are not a command line instance. Set them to the correct directory via: sudo xcode-select -s <correct-location>"
        echo "Typically, this happens when you are using the beta version of Xcode."
        echo  "...please follow instructions to install and re-run $0"
        echo "after installation, you may need to execute: xcode-select -s /Applications/Xcode.app/Contents/Developer"
        exit 1
    fi
    if [ ! -f "$(which brew)" ]; then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    brew install ctags python python3 bash-completion # ctags may no be longer needed now with flow
    pip2 install neovim --uprgrade
    pip3 install vim-vint # for vim linting
    brew install neovim
fi

# Put dotfiles in place if not already there
cloneDotFiles

set -o errexit

#########################################################
# setup colors for output 
#########################################################
# shellcheck disable=SC1090
source "${HOME}/dotfiles/colordefs.sh"

Black="$(color Black esc)"
Red="$(color Red esc)"
Green="$(color Green esc)"
Yellow="$(color Yellow esc)"
IYellow="$(color On_IYellow esc)"
Blue="$(color Blue esc)"
Purple="$(color Purple esc)"
Cyan="$(color Cyan esc)"
White="$(color White esc)"
Color_Off="$(color Color_Off esc)"

black() { echo -e "${Black}$*${Color_Off}"; }
red() { echo -e "${Red}$*${Color_Off}"; }
green() { echo -e "${Green}$*${Color_Off}"; }
yellow() { echo -e "${Yellow}$*${Color_Off}"; }
iyellow() { echo -e "${IYellow}$*${Color_Off}"; }
blue() { echo -e "${Blue}$*${Color_Off}"; }
magenta() { echo -e "${Purple}$*${Color_Off}"; }
cyan() { echo -e "${Cyan}$*${Color_Off}"; }
white() { echo -e "${White}$*${Color_Off}"; }

# setup ln options for dotfile linking
if [ "${OS}" == "mac" ] || [ "${DistroBasedOn}" = 'redhat' ]; then
    lnopts="-si"
else
    lnopts="-sb"
fi

####################################################################
# Print Menu
####################################################################
printMenu(){
    clear
    echo -e '\n\033[46;69m'"\033[1m    Headless server setup for node.js, rlwrap, Heroku toolbelt, bash eternal history, and standard config files as   "
    echo -e "         well as a standard emacs or vim developer environment depending upon specified configuration below.         "
    echo -e "See: $gitdotfiles for the repository with the configuration files to be installed\033[0m\n"
    magenta "OS: $OS"
    magenta "DIST: $DIST"
    cyan "PSEUDONAME: $PSEUDONAME"
    cyan "REV: $REV"
    cyan "DistroBasedOn: $DistroBasedOn"
    cyan "KERNEL: $KERNEL"
    cyan "MACH: $MACH"
    if [ "${nodeInstalled}" = "true" ] ; then 
        echo "node installed at: " "$(which node)"
        if [ -e /usr/local/bin/node ] ; then
            cyan "and node already globally installed at: /usr/local/bin/node"
            cyan "Will use node version: $nvmuse" 
        elif [ "${OS}" == "cygwin" ] ; then
	    cyan "nvm will not be installed on Windows/Cygwin"
            cyan  "node version:" "$(node --version)"
            cyan  "globally installed on system"
        else
            cyan "node is not globally installed. To globally install during setup, press 4 below"
            cyan "Will use node version: $nvmuse" 
        fi
    else
        if [ "${OS}" == 'cygwin' ] ; then
            red "node is not installed on Windows. To globally install during setup, press 4 below"
            red "Option 4 will use node from: ${winNode}"
        fi
    fi
    green "Application Installer: $AppInstall"  
    green "Editor and configuration to be installed: "$editorInstall  
    if [ "${herokuKey}" = "true" ] ; then
         green "Heroku key has been created and Heroku toolbelt will be installed. "
    fi
    if [ "${githubKey}" == "true" ] ; then
        green "GitHub key has been created and placed in ~/.ssh/github.rsa"
    fi
    if [ "${OS}" == "mac" ]; then
        iyellow " Mac OS users should note that this installation script relies on the use of Homebrew and may conflict "
        iyellow "                                         with use of Macports or Fink!                                 \n"
    fi
    echo " "
    echo "=============================================================================================================="
    echo "= You may also generate SSH keys for use with Heroku or GitHub prior to setup by selecting the options below ="
    echo "=============================================================================================================="
    echo " "
    if [ -e "$HOME/.ssh/heroku-rsa" ] ; then
        yellow "\t1) Heroku Key installed at ~/.ssh/heroku-rsa. Press 1 to overwrite existing key and install toolbelt."
        if [ "${herokuKey}" = "true" ] ; then
            white "Heroku Toolbelt will be (re-)installed."
        fi
    else
        white "\t1) Generate Heroku Key (~/.ssh/heroku-rsa) and install Heroku Toolbelt"
    fi
    if [ -e "$HOME/.ssh/github-rsa" ] ; then
        yellow "\t2) GitHub Key found at ~/.ssh/github-rsa.pub -- Be sure to add public key to your profile in GitHub"
    else
        white "\t2) Generate GitHub Key (~/.ssh/github-rsa)"
    fi
    if [ "${editorInstall}" = "vim" ] ; then
        white "\t3) Toggle to install emacs instead of vim "
    else
        white "\t3) Toggle to install vim instead of emacs "
    fi
    if [ -e /usr/local/bin/node ] ; then
        cyan "\t4) node already globally installed (press 4 to re-install version $nvmuse)"
    else
        if [ "${OS}" == 'cygwin' ] ; then
            cyan "\t4) Install node from ${winNode} for global use" 
        else
            white "\t4) Install node version ${nvmuse} globally "
        fi
    fi

    set +o errexit
    if whereMongo=$(which mongod 2>&1) ; then
        if [ -f "$whereMongo" ] && [ "${installMongo}" == "false" ]; then
            cyan "\t5) MongoDB already installed. Select to toggle to fresh installation" 
        elif [ "${installMongo}" = "true" ]; then
            yellow "\t5) MongoDB will be (re-)installed; Select to toggle" 
        else
            white "\t5) MongoDB not currently installed; Select to install" 
        fi
    else
        white "\t5) MongoDB not found; Select to install" 
    fi
    set -o errexit
    red "\t6) Exit Now!"
    green "\t7) Continue Setup"
    echo -e " "
    red "Press ^C, q or 6 if the above system information is not correct or you wish to abort installation"
    white  "------------------------------------------------------------------------------------------------- "
    green "Press press 7, c, or y to proceed"
    read -r option;
    # shellcheck disable=SC2143
    while [[ $option -gt 12 || ! "$(echo "$option" | grep '^[1-7qQyc]$')" ]]
    do
        printMenu
    done
    if [[ "$option" == "7" || "$option" == "c" || "$option" == "y" ]]; then
        echo "Starting installation..."
        echo 
        setFlags
        sleep 1
        return;
    fi
    runOption
}

####################################################################
# Run an Option
####################################################################
runOption(){
    case $option in
        1) genHeroku;;
        2) genGitHub;;
        3) toggleVimEmacs;;
        4) nodeGlobalInstall;;
        5) InstallMongo;;
        6) exit;;
        q) exit;;
        Q) exit;;
        y) setFlags;;
        c) setFlags;;
        6) setFlags
    esac 
    echo "Press return to continue"
    # shellcheck disable=SC2034
    read -r x
    printMenu
}

# set to exit on any errors before non-interactive mode check
set -o errexit

# Only have susccesfully used following as means to test for interactivity
if tty -s ; then
    echo "Interactive mode..."
    printMenu
else
    red "non-interactive installation -- will use defaults without any editor setup"
    lnopts="-sf " # force linking to overwrite existing files
    editorInstall="none" # do not load editor configs
    echo "OS: $OS"
    echo "DIST: $DIST"
    echo "PSEUDONAME: $PSEUDONAME"
    echo "REV: $REV"
    echo "DistroBasedOn: $DistroBasedOn"
    echo "KERNEL: $KERNEL"
    echo "MACH: $MACH"
    echo "Will use node version: $nvmuse" 
    echo "Application Installer: $AppInstall"  
fi

# The following is derived for a simple setup originally designed for Ubuntu EC2 instances
# for headless setup.  Now modified to support MacOS, Cygwin, RHEL and other Linux systems.



if [ "${OS}" != "cygwin" ]; then  # install nvm and other packages for *nix 
  installGit  
  installNVM 

  # moving set -u since nvm installation has undefined variables
  set -u # exit if undefined variables
  
  # Set npm to local version and then use sudo for global installation
  npm="$HOME/.nvm/versions/node/$nvmuse/bin/npm"

    
  if [ "$nvmInstalled" = "false" ]; then
    echo "use sudo password for following if prompted"
    sudo "$npm" install -g eslint js-beautify jsonlint repl.history
  else
    "$npm" install -g eslint js-beautify jsonlint repl.history npm-completion
  fi

  # Install rlwrap to provide libreadline features with node
  # See: http://nodejs.org/api/repl.html#repl_repl
  if [ "${DIST}" == "CentOS" ] ; then # CentOS requires compilation from source with dependencies
      if [ ! -f "$(which rlwrap)" ] ; then 
          $AppInstall install readline-devel 
          curl http://git.savannah.gnu.org/cgit/readline.git/snapshot/readline-master.tar.gz > /tmp/readline-master.tar.gz 
          pushd /tmp/ 
          tar -zxvf /tmp/readline-master.tar.gz  
          cd readline-master || error "unable to cd to readline-master"
          ./configure 
          make 
          sudo make install 
          popd
        else
          echo 'rlwrap already installed!'
        fi
  else
      $AppInstall install -y rlwrap
  fi 
else # install node globally via binary
    npm="npm"
    if [ $nodeInstalled == "false" ] ; then
      nodeGlobalInstall
    fi
    # install apt-cygwin for individual cygwin commands
    which "$AppInstall" > /dev/null 2>&1
    if [ $? -eq 1 ] ; then
      echo -e "installing apt-cyg from GitHub"
      curl https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg > /usr/bin
      chmod +x /usr/bin/apt-cyg
    fi
    $AppInstall install rlwrap
    $AppInstall install ncurses # for clear command
    $npm install -g eslint js-beautify jsonlint
fi

#Install MongoDB; see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/
if [ "${installMongo}" == "true" ]; then
    if [ "${OS}" == "mac" ]; then
      $AppInstall install mongodb 
    elif [ "${DistroBasedOn}" == "redhat" ]; then 
        echo "Must manually install MongoDB on RHEL/CentOS"
        echo "       Mongo DB not installed!!"
    elif [ "${OS}" == "cygwin" ] ; then
    	echo not installing Mongo from command line
    	echo -e 'Use Windows Mongo installation (http://www.mongodb.org/downloads)'
    else
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
        echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/10gen.list
        $AppInstall update
        $AppInstall install mongodb-10gen
    fi
fi

# Select whether to install vim or emacs configuration/files:
if [ "${editorInstall}" == "emacs" ] ; then

# Install emacs24 on other OSes than Mac OS
    if [ "${OS}" == "mac" ]; then
        $AppInstall install --cocoa emacs 
    elif [ "${DistroBasedOn}" == "redhat" ]; then
        echo "Must manually install emacs24 on RHEL"
        echo "      Emacs not installed!!"
    else
# https://launchpad.net/~cassou/+archive/emacs
        $AppInstall add-apt-repository -y ppa:cassou/emacs
        $AppInstall update
        $AppInstall install -y emacs24 emacs24-el emacs24-common-non-dfsg
    fi

elif [ "${OS}" != "cygwin" ] ; then
# Install VIM configuration files including vundle and colorschemes
    # These use configuration specified in dotfiles/.vimrc:
    if [ -d "$HOME/.vim/bundle" ]; then
        rm -rf "$HOME/.vim/bundle"
    fi
    mkdir -p "$HOME/.vim/bundle"
    git clone $vundle "$HOME/.vim/bundle/vundle"
fi

cd "$HOME" || error unable to cd

if [ "${OS}" == "mac" ]; then
    set +o errexit
    ln "${lnopts}" dotfiles/.screenrc "$HOME"
    ln "${lnopts}" dotfiles/.bash_profile "$HOME"
    ln "${lnopts}" dotfiles/.bashrc "$HOME"
    ln "${lnopts}" dotfiles/.jshintrc "$HOME"
    ln "${lnopts}" dotfiles/.bash_logout "$HOME"
    set -o errexit
else
    ln "${lnopts}" dotfiles/.screenrc "$HOME"
    ln "${lnopts}" dotfiles/.bash_profile "$HOME"
    ln "${lnopts}" dotfiles/.bashrc "$HOME"
    ln "${lnopts}" dotfiles/.jshintrc "$HOME"
    ln "${lnopts}" dotfiles/.bash_logout "$HOME"
fi


# append to custom rc file rather than linking -- this is changed from Balaji's script
cat dotfiles/.bashrc_custom >> "$HOME/.bashrc_custom"

# Select whether to link vim or emacs dotfiles:
if [ "${editorInstall}" == "emacs" ] ; then
        ln -sf dotfiles/.emacs.d .  
elif [ "${editorInstall}" == "vim" ] ; then
    set +o errexit
    if [ "${OS}" != "cygwin" ] ; then 
        rm -f "${HOME}/.vimrc"
        cp -f "${HOME}/dotfiles/.vimrc" "${HOME}"

        # install pathogen
        mkdir -p "${HOME}/.vim/autoload"
        mkdir -p "${HOME}/.vim/bundle"
        curl -LSso "${HOME}/.vim/autoload/pathogen.vim" https://tpo.pe/pathogen.vim


        # setup vim on CentOS
        if [ "${DIST}" == "CentOS" ] ; then
            $AppInstall install  vim-X11 vim-common vim-enhanced vim-minimal
            echo "alias vi=vim " >> ~/.bashrc_custom
        fi 

    # setup pathogen specific installs by using git clones
    # note: these should installed on ~/vimfiles on Windows...
        cd "${HOME}/.vim" || error "unable to cd ${HOME}/.vim"
        # shellcheck disable=SC1090
        source "${HOME}/dotfiles/.git_template/config.sh"
        # git init
        # git submodule add "${commandt}" bundle/command-t 
        yellow "Installing ${commandt} as pathogen git submodule; cd ~/.vim/bundle/ \& use git pull to update"
        # git clone https://github.com/kien/ctrlp.vim.git bundle/ctrlp.vim
        # yellow "Installing ctrl-p..."

    # Warn user that non-interactive vim will show and to wait for process to complete
        # echo " "
        # echo -e '\n\033[43;35m'"  vim will now be run non-interactively to install the bundles and plugins\033[0m   "
        # echo -e '\n\033[43;35m'" Please wait for this process to be completed -- it may take a few moments\033[0m  "
        # echo " "
        # sleep 7
    # Install bundles and vim-plug for neovim
        curl -fLo ${HOME}/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        if [ "${OS}" == "mac" ]; then # install VimR
            echo "Install latest VimR from https://github.com/qvacua/vimr/releases"
            echo "Then remember to run :PlugInstall"
        else # install Neovim
            curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
            chmod u+x nvim.appimage
            ./nvim.appimage
        fi
    else
        echo -e "not installing VIM bundles on Cygwin..."
        # add Cygwin specifics to customized bashrc 
        echo "export TERM=cygwin" >> ~/.bashrc_custom
        echo "alias sudo='cygstart --action=runas' " >> ~/.bashrc_custom
    fi
    set -o errexit
fi

#If using Mac, copy terminal settings files over to home as well
if [ "${OS}" == "mac" ]; then
    mkdir -p "$HOME/.term_settings"
    ln "${lnopts}" dotfiles/term_settings/* "$HOME/.term_settings"
else
    rm -rf dotfiles/term_settings/
fi 

#Copy over Chrome debugger environment for MAC usage
if [ "${OS}" == "mac" ]; then
    echo 'export CHROME_BIN=/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary' >> ~/.bashrc_custom
    # shellcheck disable=SC2016 
    echo 'DebugBrowser="${CHROME_BIN}"'  >> ~/.bashrc_custom
# add Visual Studio config for git
    git config --global core.autocrlf input
    git config --global core.safecrlf false
fi
# add better git log
git config --global alias.lg1 "log --graph --abbrev-commit --decorate --first-parent --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"

#Install Heroku tool belt if Heroku keys were installed in ~/.ssh
#Install wget and use different install if Mac OS:
if [ "$herokuKey" == "true" ]; then
    if [ "${OS}" == "mac" ]; then
        $AppInstall install wget
        wget -qO- https://toolbelt.heroku.com/install.sh | sh
    else
        wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh
    fi
fi

# Install Bash and Git Flow Completion:
installBashCompletion 

# Install Shell Check
installShellCheck 

# Use favorite VIM color scheme
mkdir -p "${HOME}/.vim/colors"
cp ~/dotfiles/neon-custom.vim "${HOME}/.vim/colors/"

# Copy HTML tag folding vim script to .vim
cp ~/dotfiles/html.vim ~/.vim

# Copy git template files for ctags to home dir
cp -R ~/dotfiles/.git_template/ "${HOME}/.git_template"

# some niceties for MacOS, and replae crappy Xcode git
if [ "${OS}" == "mac" ]; then
  brew install wget git python python3
  npm i -g npm-completion
fi

echo "This script automatically installed ${gitdotfiles} to ~/dotfiles. These files can be used with Docker shell" 
echo " "
echo "Be sure to logout and log back in to properly setup your environment"
echo "Copy appropriate config file (AngularJS, React, Flow, etc) from within ~/.git_template/ to ~/.git_template/config"
echo "In the new shell, execute ~/.git_template/config.sh to finishing setting up git to auto-index ctags"
echo "Then execute: git config --global init.templatedir '~/.git_template'"
