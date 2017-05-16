# bash login initialization

# source the system wide bashrc if it exists
#if [ -e /etc/bash.bashrc ] ; then
#  source /etc/bash.bashrc
#fi
#if [ -e /etc/bashrc ] ; then
#  source /etc/bashrc
#fi

# osx hack.
# fixes strangeness caused by path_helper
# see: http://superuser.com/q/544989
if [[ $(uname) = 'Darwin' && -f /etc/profile ]]; then
  PATH=""
  source /etc/profile
fi

# source the users bashrc if it exists
if [ -e ${HOME}/.bashrc ] ; then
  source ${HOME}/.bashrc
fi

