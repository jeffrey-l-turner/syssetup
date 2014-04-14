syssetup
========

script to setup a new system

This is simply a script customized cloned from github.com:startup-class/setup.git for Mac OS as well as Ubuntu, Redhat,  and Fedora instances.


setup.git
=========
This setup script now offers an interactive menu for setup of both ssh keys (for Heroku and Github) as well as identifying the system parameters prior to invocation. 

Configure both the machine and your individual development environment as
follows:

`curl https://raw.github.com/jeffrey-l-turner/syssetup/master/setup.sh > ./setup.sh; bash ./setup.sh`

After optionally generating Heroku and GitHub keys, place the public keys (~/.ssh/*.pub) appropriately within your GitHub and Heroku profiles/accounts. 

Test by executing: `ssh -T git@github.com`; and
test by executing: `ssh -vT git@heroku.com`; 
Note: shell request will fail but message will show "Authentication succeeded (publickey)."

Logout of shell and log back in to properly setup environment.


See also http://github.com/jeffrey-l-turner/dotfiles
