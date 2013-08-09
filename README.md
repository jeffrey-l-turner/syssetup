syssetup
========

script to setup a new system

This is simply a script customized cloned from github.com:startup-class/setup.git for my Ubuntu instances.


setup.git
=========
Clone and run this on a new EC2 instance running Ubuntu (tested on 12 and 13). You may wish to setup and install ssh keys prior to setup. To do so:
`ssh-keygen -t rsa -f ~/.ssh/<key-name>` then `chmod 400 ~/.ssh/<key-name>`; copy/paste key to Github account (under account settings). 

Configure both the machine and your individual development environment as
follows:

`curl https://raw.github.com/jeffrey-l-turner/syssetup/master/setup.sh | bash`

edit ~/.ssh/config and replace <key-name> with gen'ed ssh key; 
test by executing: `ssh -T git@github.com`

See also http://github.com/jeffrey-l-turner/dotfiles
