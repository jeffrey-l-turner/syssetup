#!/bin/bash

datetime=$(date +%Y%m%d%H%M%S)
# Version of Node to use:
nvmuse="v0.11.12" 
# binary of node to use on Windows/Cygwin
winNode="http://nodejs.org/dist/${nvmuse}/x64/node-${nvmuse}-x64.msi"

# location of dotfiles on Git
gitdotfiles="https://github.com/jeffrey-l-turner/dotfiles.git"

# location of vundle on Git
vundle="https://github.com/gmarik/vundle.git"
 

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

gitInstalled="false"
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
        cd $HOME
        installGit
        if [ -d ./dotfiles/ ]; then
            mv dotfiles dotfiles.old
        fi
        if [ -d .emacs.d/ ]; then
            mv .emacs.d .emacs.d~
        fi
        git clone $gitdotfiles
        if [ "${OS}" != "mac" ]; then
            rm -rf $HOME/dotfiles/term_settings
        fi
    fi
    dotFilesCloned="true"
}

nvmInstalled="false"
installNVM (){
    if [ "$nvmInstalled" == "false" ]; then
        # Install nvm: node-version manager
        # https://github.com/creationix/nvm
        # nvm locations have frequently changed
        # using v0.17.0 currently from githubusercontent:
        curl https://raw.githubusercontent.com/creationix/nvm/v0.17.0/install.sh | bash

        # Load nvm and install latest production node
        source $HOME/.nvm/nvm.sh
        nvm install $nvmuse
        nvm use $nvmuse
        nvm alias default $nvmuse
        nvmInstalled="true"
    else
        nvmInstalled="true"
    fi
}

which node > /dev/null 2>&1 # for Cygwin compatibility
if [ $? -eq 0 ]; then
    nodeInstalled="true"
else
    nodeInstalled="false"
fi

# Global installation for node:
nodeGlobalInstall() {
    if [ "${OS}" == "cygwin" ]; then
      wget $winNode
      msi=`echo $winNode | sed -e 's/.*\///'`
      mv ${msi} /tmp
      echo "running msiexec.exe to install: ${msi}"
      run msiexec.exe /i `cygpath -d /tmp/$msi` 
      echo "restart system prior to installing rest of $0"
      #rm -f ${msi} 
    else
      echo -e  "copying node files for version $nmuse... enter sudo password if prompted"
      echo -e  "enter sudo password if prompted"
      echo -e " "
      if [ "${OS}" == "mac" ]; then # globally install node for Mac users via Homebrew
          installNVM
          brew install node
      else
          installNVM
          n=$(which node);n=${n%/bin/node}; chmod -R 755 $n/bin/*; sudo cp -r $n/{bin,lib,share} /usr/local
      fi
    fi
}


####################################################################
# Get System Info
####################################################################
shootProfile(){
    OS=`lowercase \`uname\``
    KERNEL=`uname -r`
    MACH=`uname -m`

    if [ "${OS}" == "darwin" ]; then
        OS="mac"
        REV=`uname -r`
        PSEUDONAME="Darwin"
        DistroBasedOn='BSD'
        AppInstall="brew "
        DIST="Apple OS X"
    elif [ `echo "${OS}" | cut -b 1-6` == "cygwin" ]; then
        OS="cygwin"
        DIST="Windows POSIX"
        REV=`uname -r`
        PSEUDONAME=`uname`
        DistroBasedOn='POSIX'
        AppInstall="apt-cyg "
    else
        OS=`uname`
        if [ "${OS}" = "Linux" ] ; then
            if [ -f /etc/redhat-release ] ; then
                DistroBasedOn='RedHat'
                DIST=`cat /etc/redhat-release |sed s/\ release.*//`
                PSEUDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
                AppInstall="sudo yum "
            elif [ -f /etc/SuSE-release ] ; then
                DistroBasedOn='SuSe'
                PSEUDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
                REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
                AppInstall="exit 2"
            elif [ -f /etc/mandrake-release ] ; then
                DistroBasedOn='Mandrake'
                PSEUDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
                REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
                AppInstall="exit 2"
            elif [ -f /etc/debian_version ] ; then
                DistroBasedOn='Debian'
                if [ -f /etc/lsb-release ] ; then
                        DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
                            PSEUDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F=  '{ print $2 }'`
                            REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
                        fi
                AppInstall="sudo apt-get "
            fi
            if [ -f /etc/UnitedLinux-release ] ; then
                DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
            fi
            OS=`lowercase $OS`
            DistroBasedOn=`lowercase $DistroBasedOn`
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


# Setup for config files using ssh:
if [ -d $HOME/.ssh/ ]; then
    touch $HOME/.ssh/config
    chmod 600 $HOME/.ssh/config
else
    mkdir $HOME/.ssh
    touch $HOME/.ssh/config
    chmod 600 $HOME/.ssh/config
fi

# These are functions to setup ssh keys for Heroku and GitHub:
# The keys must still be registered with the respective accounts by the user
herokuKey="false"
genHeroku(){
    echo -e '\t Generating Heroku Key (~/.ssh/heroku-rsa)'
    echo "Enter email address for Heroku key:"
    read email;
    ssh-keygen -t rsa -C "$email" -f $HOME/.ssh/heroku-rsa
    herokuKey="true"
    cloneDotFiles;
    cat $HOME/dotfiles/ssh-config-heroku >> $HOME/.ssh/config
    echo "Note: you must still upload your key to your Heroku account!"
}

githubKey="false"
genGitHub(){
    echo -e '\t Generating GitHub Key (~/.ssh/github-rsa)'
    echo "Enter email address for GitHub key:"
    read email;
    ssh-keygen -t rsa -C "$email"  -f $HOME/.ssh/github-rsa
    githubKey="true"
    cloneDotFiles;
    cat $HOME/dotfiles/ssh-config-github >> $HOME/.ssh/config
    echo "Note: you must still upload your key to your GitHub profile!"
}

setFlags(){
    readonly "githubKey"
    readonly  "herokuKey"
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

shootProfile

# If using Mac OS, then check if xcode is installed, then install brew & ctags
if [ "${OS}" == "mac" ]; then
    if [ -e "`which xcode-select`" ]; then
        echo "xcode version: `xcode-select --version` installed"
    else
        echo "xcode command line tools are not installed..." 
        echo "please install xcode before proceeding" 
        echo " (see:http://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12 )"
        echo ""
        echo "Attempting to execute make... please follow instructions to install xcode and re-run $0"
        make
        exit 1
    fi
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install ctags
fi

# setup ln options for dotfile linking
if [ "${OS}" == "mac" ]; then
    lnopts="-si "
else
    lnopts="-sb "
fi

####################################################################
# Print Menu
####################################################################
printMenu(){
    clear
    echo -e '\n\033[46;69m'"\033[1m    Headless server setup for node.js, rlwrap, Heroku toolbelt, bash eternal history, and standard config files as   "
    echo -e "         well as a standard emacs or vim developer environment depending upon specified configuration below.         "
    echo -e "See: $gitdotfiles for the repository with the configuration files to be installed\033[0m\n"
    echo "OS: $OS"
    echo "DIST: $DIST"
    echo "PSEUDONAME: $PSEUDONAME"
    echo "REV: $REV"
    echo "DistroBasedOn: $DistroBasedOn"
    echo "KERNEL: $KERNEL"
    echo "MACH: $MACH"
    if [ "${nodeInstalled}" = "true" ] ; then 
        echo "node installed at: " `which node`
        if [ -e /usr/local/bin/node ] ; then
            echo "and node already globally installed at: /usr/local/bin/node"
            echo "Will use node version: $nvmuse" 
        elif [ "${OS}" == "cygwin" ] ; then
	    echo -e "nvm will not be installed on Windows/Cygwin"
            echo -e "node version:" `node --version`
            echo -e "is currently installed on system"
        else
            echo "node is not globally installed. To globally install during setup, press 4 below"
            echo "Will use node version: $nvmuse" 
        fi
    else
        if [ "${OS}" == 'cygwin' ] ; then
            echo "node is not installed on Windows. To globally install during setup, press 4 below"
            echo "Option 4 will use node from: ${winNode}"
        fi
    fi
    echo "Application Installer: $AppInstall"  
    echo "Editor and configuration to be installed: "$editorInstall  
    if [ "${herokuKey}" = "true" ] ; then
         echo "Heroku key has been created and Heroku toolbelt will be installed. "
    fi
    if [ "${githubKey}" == "true" ] ; then
        echo "GitHub key has been created and placed in ~/.ssh/github.rsa"
    fi
    if [ "${OS}" == "mac" ]; then
        echo -e '\n\033[43;35m'"Mac OS users should note that this installation script relies on the use of Homebrew and may conflict"
        echo -e "                                      with use of Macports or Fink!                                  \033[0m\n"
    fi
    echo " "
    echo "=============================================================================================================="
    echo "= You may also generate SSH keys for use with Heroku or GitHub prior to setup by selecting the options below ="
    echo "=============================================================================================================="
    echo " "
    if [ -e "$HOME/.ssh/heroku-rsa" ] ; then
        echo -e "\t1) Heroku Key installed at ~/.ssh/heroku-rsa. Press 1 to overwrite existing key and install toolbelt."
        if [ "${herokuKey}" = "true" ] ; then
            echo -e "Heroku Toolbelt will be (re-)installed."
        fi
    else
        echo -e "\t1) Generate Heroku Key (~/.ssh/heroku-rsa) and install Heroku Toolbelt"
    fi
    if [ -e "$HOME/.ssh/github-rsa" ] ; then
        echo -e "\t2) GitHub Key found at ~/.ssh/github-rsa.pub -- Be sure to add public key to your profile in GitHub"
    else
        echo -e "\t2) Generate GitHub Key (~/.ssh/github-rsa)"
    fi
    if [ "${editorInstall}" = "vim" ] ; then
        echo -e "\t3) Toggle to install emacs instead of vim "
    else
        echo -e "\t3) Toggle to install vim instead of emacs "
    fi
    if [ -e /usr/local/bin/node ] ; then
        echo -e "\t4) node already globally installed (press 4 to re-install version $nvmuse)"
    else
        if [ "${OS}" == 'cygwin' ] ; then
            echo -e "\t4) Install node from ${winNode} for global use" 
        else
            echo -e "\t4) Install node version ${nvmuse} globally "
        fi
    fi
    echo -e "\t5) Exit Now!"
    echo -e "\t6) Continue Setup"
    echo -e " "
    echo "Press ^C, q or 5 if the above system information is not correct or you wish to abort installation"
    echo -e " "
    echo "Press press 6, c, or y to proceed"
    read option;
    while [[ $option -gt 12 || ! $(echo $option | grep '^[1-6qQyc]$') ]]
    do
        printMenu
    done
    if [[ "$option" == "6" || "$option" == "c" || "$option" == "y" ]]; then
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
        5) exit;;
        q) exit;;
        Q) exit;;
        y) setFlags;;
        c) setFlags;;
        6) setFlags
    esac 
    echo "Press return to continue"
    read x
    printMenu
}


# Only have susccesfully used following as means to test for interactivity
tty -s
if [[ $? -eq 0 ]] ; then
    echo "Interactive mode..."
    printMenu
else
    echo "non-interactive installation -- will use defaults without any editor setup"
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

  # Set npm to local version and then use sudo for global installation
  npm="$HOME/.nvm/$nvmuse/bin/npm"
  
  # Install jshint, eslint, jslint and beautify to allow checking of JS code within emacs and node history (locally)
  # http://jshint.com/
  echo "use sudo password for following if prompted"
  sudo $npm install -g jshint
  sudo $npm install -g jslint
  sudo $npm install -g eslint
  sudo $npm install -g js-beautify 
  sudo $npm install repl.history

  # Install rlwrap to provide libreadline features with node
  # See: http://nodejs.org/api/repl.html#repl_repl
  $AppInstall install -y rlwrap
else # install node globally via binary
  if [ nodeInstalled == "false" ] ; then
    nodeGlobalInstall
  fi
  # install apt-cygwin for individual cygwin commands
  which $AppInstall > /dev/null 2>&1
  if [ $? -eq 1 ] ; then
    echo -e "installing apt-cyg from GitHub"
    wget https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
    mv apt-cyg /usr/bin
    chmod +x /usr/bin/apt-cyg
  fi
  $AppInstall install rlwrap
  $npm install eslint -g
  $npm install js-beautify -g
fi

#Install MongoDB; see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/
if [ "${OS}" == "mac" ]; then
  $AppInstall install mongodb 
elif [ "${DistroBasedOn}" == "redhat" ]; then
    echo "Must manually install MongoDB on RHEL"
    echo "       Mongo DB not installed!!"
else
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/10gen.list
    $AppInstall update
    $AppInstall install mongodb-10gen
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
else
# Install VIM configuration files including vundle and colorschemes
    # These use configuration specified in dotfiles/.vimrc:
    if [ -d $HOME/.vim/bundle ]; then
        mv $HOME/.vim/bundle $HOME/.vim/bundle.old
    fi
    mkdir -p $HOME/.vim/bundle
    git clone $vundle $HOME/.vim/bundle/vundle
fi

# Call to put dotfiles in place if not already there
cloneDotFiles;
cd $HOME

ln $lnopts dotfiles/.screenrc $HOME
ln $lnopts dotfiles/.bash_profile $HOME
ln $lnopts dotfiles/.bashrc $HOME
ln $lnopts dotfiles/.jshintrc $HOME
ln $lnopts dotfiles/.bash_logout $HOME

# append to custom rc file rather than linking -- this is changed from Balaji's script
cat dotfiles/.bashrc_custom >> $HOME/.bashrc_custom

# Select whether to link vim or emacs dotfiles:
if [ "${editorInstall}" == "emacs" ] ; then
        ln -sf dotfiles/.emacs.d .
   elif [ "${editorInstall}" == "vim" ];then 
        cp -f dotfiles/.vimrc $HOME
    # Warn user that non-interactive vim will show and to wait for process to complete
        echo " "
        echo -e '\n\033[43;35m'"  vim will now be run non-interactively to install the bundles and plugins\033[0m   "
        echo -e '\n\033[43;35m'" Please wait for this process to be completed -- it may take a few moments\033[0m  "
        echo " "
        sleep 7
    # Install bundles and plugins for vim
        vim +PluginInstall +qall
        vim +BundleInstall +qall
        echo ":colorscheme refactor" >> $HOME/.vimrc # add my preferred colorscheme to end of .vimrc
fi

#If using Mac, copy terminal settings files over to home as well
if [ "${OS}" == "mac" ]; then
    mkdir -p $HOME/.term_settings
    ln $lnopts dotfiles/term_settings/* $HOME/.term_settings
fi

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

echo " "
echo "Be sure to logout and log back in to properly setup your environment"
echo "In the new shell, execute ~/.git_template/config.sh to finishing setting up git to auto-index ctags"

