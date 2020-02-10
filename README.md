syssetup
========

script to setup a new system

This script is loosely based on and originally cloned from github.com:startup-class/setup.git. It supports both interactive and headless install for Mac OS as well as Ubuntu, Redhat, CentOS and Fedora systems.
If you intend to run this on a Mac, install the Xcode command line tools, prior to executing the curl commands, below. Homebrew will then automatically be installed by the script.

setup.sh
=========
This setup script offers an interactive menu for setting up and ssh-agent for ssh keys (all private keys associated with .pub keys in ~/.ssh) as well as identifying the system parameters prior to invocation.

The script has been updated to suport an AngularJS development environment using vim with ctags as well as eslint. The scripts will automatically re-index ctags when working with git repositories.

Run the following from a terminal window on your virtual machine to interactively setup your system:

```sh
curl https://raw.githubusercontent.com/jeffrey-l-turner/syssetup/master/setup.sh > ./setup.sh; chmod +x ./setup.sh; bash ./setup.sh
```

Alternatively, you may also use a non-interactive setup using the defaults:

`curl https://raw.githubusercontent.com/jeffrey-l-turner/syssetup/master/setup.sh | bash`

These defaults for non-interactive setup will not install editors, and are primarily designed for running a headless Node.js system.

After running interactive setup, you may optionally generate ssh keys. Place the public keys (~/.ssh/\*.pub) appropriately within your associated profiles/accounts (e.g. GitHub).

Test by executing: ```ssh -T git@github.com``` (or for example: ```ssh -vT git@heroku.com```).
   _Note: shell request will fail but message will show: "Authentication succeeded (publickey)."_

Logout of shell and log back in to properly setup environment.

Then, execute:
```sh
 ~/.git_template/config.sh
```
to finish setting up git for ctagging, etc. in the new shell.

Remember to `ssh-add -K ~/.ssh/id_ed25519` on your Mac to add these to your keychain. after setup or simply use these [dotfiles](http://github.com/jeffrey-l-turner/dotfiles).
for your `.bash*` setup:

