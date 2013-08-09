syssetup
========

script to setup a new system


This is simply a script customized cloned from github.com:startup-class/setup.git for my Ubuntu instances.


setup.git
=========
Clone and run this on a new EC2 instance running Ubuntu (tested on 12 and 13). You may wish to setup and install ssh keys prior to setup. To do so:
`ssh-keygen -t rsa -f ~/.ssh/<keyname>`
copy/paste key to Github account (under account settings)
test by executing: `ssh -T git@github.com`

Configure both the machine and your individual development environment as
follows:

```sh
cd $HOME
sudo apt-get install -y git-core
git clone git@github.com:jeffrey-l-turner/syssetup.git
sh ./syssetup/setup.sh   
```

See also http://github.com/jeffrey-l-turner/dotfiles
