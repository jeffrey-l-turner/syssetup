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

edit ~/.ssh/config and replace <key-name> with gen'ed ssh key; if setting up Heroku keys, also modify <key-name>-heroku in config file.
execute `heroku keys:add <key-name>-heroku`; Note: this key can be the same as the GitHub key;

Test by executing: `ssh -T git@github.com`; and
test by executing: `ssh -vT git@heroku.com`; Note: shell request will fail but message will show "Authentication succeeded (publickey)."

Logout of shell and log back in to properly setup environment.


See also http://github.com/jeffrey-l-turner/dotfiles
