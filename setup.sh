#!/bin/bash
 
datetime=$(date +%Y%m%d%H%M%S)
# Version of Node to use:
nvmuse="v0.10.19"

# location of dotfiles on Git
gitdotfiles="https://github.com/jeffrey-l-turner/dotfiles.git"

# location of vundle on Git
vundle="https://github.com/gmarik/vundlegit"
vimColorSchemes="git@github.com:dgvigil/vim-colorschemes.git"
    

lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

# git pull and install dotfiles if not already cloned previously- modified as function for use with adding ssh keys
dotFilesCloned="false"
cloneDotFiles(){
    if [ "$dotFilesCloned" == "false" ]; then
        cd $HOME
        if [ -d ./dotfiles/ ]; then
            mv dotfiles dotfiles.old
        fi
        if [ -d .emacs.d/ ]; then
            mv .emacs.d .emacs.d~
        fi
        git clone $gitdotfiles
    fi
    dotFilesCloned="true"
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
        llopts=" "
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
            readonly OS
            readonly DIST
            readonly DistroBasedOn
            readonly PSEUDONAME
            readonly REV
            readonly KERNEL
            readonly MACH
        fi

    fi
}


# Setup for config files using ssh:
if [ -d $HOME/.ssh/ ]; then
    touch .ssh/config
    chmod 600 .ssh/config
else
    mkdir $HOME/.ssh
    touch .ssh/config
    chmod 600 .ssh/config
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

####################################################################
# Print Menu
####################################################################
printMenu(){
    
    clear
    echo -e '\n\033[46;69m'"\033[1m    Headless Server setup for Node.js, rlwrap, Heroku toolbelt, and standard config files as well as                 "
    echo -e "         setting up a standard emacs or vim developer environment depending upon specified configuration below.      "
    echo -e "See: $gitdotfiles for the repository with the configuration files to be installed\033[0m\n"
    echo "OS: $OS"
    echo "DIST: $DIST"
    echo "PSEUDONAME: $PSEUDONAME"
    echo "REV: $REV"
    echo "DistroBasedOn: $DistroBasedOn"
    echo "KERNEL: $KERNEL"
    echo "MACH: $MACH"
    echo "Will use node version: $nvmuse" 
    echo "Application Installer: $AppInstall"  
    if [ "${editorInstall}" = "vim" ] ; then
         echo "Editor and configuration to be installed: "$editorInstall  
    else
         echo "Editor and configuration to be installed: "$editorInstall  
    fi
    if [ "${herokuKey}" = "true" ] ; then
         echo "Heroku key has been created and Heroku toolbelt will be installed. "
    fi
    if [ "${OS}" == "mac" ]; then
        echo -e '\n\033[43;35m'"Mac OS users should note that this installation script relies on the use of Homebrew and may conflict"
        echo -e "with use of Macports or Fink!\033[0m\n"
    fi
    echo "=============================================================================================================="
    echo "= You may also generate SSH keys for use with Heroku or GitHub prior to setup by selecting the options below ="
    echo "=============================================================================================================="
    echo -e "\t1) Generate Heroku Key (~/.ssh/heroku-rsa) and install Heroku Toolbelt"
    echo -e "\t2) Generate GitHub Key (~/.ssh/github-rsa)"
    if [ "${editorInstall}" = "vim" ] ; then
        echo -e "\t3) Toggle to install emacs instead of vim "
    else
        echo -e "\t3) Toggle to install vim instead of emacs "
    fi
    echo -e "\t4) Exit Now!"
    echo -e "\t5) Continue Setup"
    echo "Press ^C, q or 4 if the above system information is not correct or you wish to abort installation"
    echo " "
    echo "Press press 5, c, or y to proceed"
    read option;
    while [[ $option -gt 12 || ! $(echo $option | grep '^[1-5qQyc]$') ]]
    do
        printMenu
    done
    if [ "$option" == "5" ]; then
        echo "Starting installation..."
        echo 
        wait 1
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
        4) exit;;
        q) exit;;
        Q) exit;;
        y) setFlags;;
        c) setFlags;;
        5) setFlags
    esac 
    echo "Press return to continue"
    read x
    printMenu
}

printMenu

# The following is derived for a simple setup originally designed for Ubuntu EC2 instances
# for headless setup.  Now modified to support MacOS, RHEL and other Linux systems.


# If using Mac OS, then install brew
if [ "${OS}" == "mac" ]; then
    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# Install nvm: node-version manager
# https://github.com/creationix/nvm
if [ "${OS}" == "mac" ]; then
    $AppInstall install git
else
    $AppInstall install -y git-core
fi
curl https://raw.github.com/creationix/nvm/master/install.sh | sh

# Load nvm and install latest production node
source $HOME/.nvm/nvm.sh
nvm install $nvmuse
nvm use $nvmuse

# Install jshint to allow checking of JS code within emacs and node history (locally)
# http://jshint.com/
sudo npm install -g jshint
sudo npm install -g jslint
sudo npm install -g js-beautify 
npm install repl.history

# Install rlwrap to provide libreadline features with node
# See: http://nodejs.org/api/repl.html#repl_repl
$AppInstall install -y rlwrap

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
    if [ -d $HOME/.vim/ ]; then
        mkdir $HOME/.vim/bundle
    else
        mkdir $HOME/.vim
        mkdir $HOME/.vim/bundle
    fi
    # These use configuration specified in dotfiles/.vimrc:
    git clone $vundle $HOME/vim/bundle/vundle
    git clone $vimColorSchemes $HOME/.vim
fi

# Call to put dotfiles in place
cloneDotFiles;
cd $HOME

if [ "${OS}" == "mac" ]; then
    lnopts="-si "
else
    lnopts="-sb "
fi
ln $lnopts dotfiles/.screenrc .
ln $lnopts dotfiles/.bash_profile .
ln $lnopts dotfiles/.bashrc .

# append to custom rc file rather than linking -- this is changed from Balaji's script
cat dotfiles/.bashrc_custom >> .bashrc_custom
ln $lnopts dotfiles/.bash_logout .

# Select whether to link vim or emacs dotfiles:
if [ "${editorInstall}" == "emacs" ] ; then
    ln -sf dotfiles/.emacs.d .
else
    ln $lnopts dotfiles/.vimrc
    # Install bundles and plugins for vim
    vim +PluginInstall +qall
    vim +BundleInstall +qall
fi

#If using Mac, copy terminal settings files over to home as well
if [ "${OS}" == "mac" ]; then
    ln $lnopts dotfiles/.term_settings/* ./term_settings
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

