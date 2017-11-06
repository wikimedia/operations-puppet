# bash startup config
#
# Bryan Davis <bd808@bd808.com>

# make sure HOME is set and non-null
: ${HOME=~}

# bash config dir. Defaults to ~/.bash but you can override if sourcing
# eg: BASH_CONF=~bd808/.bash source ~bd808/.bashrc
: ${BASH_CONF=${HOME}/.bash}

# who am i
: ${USER=$(id -un)}

# default umask rw-rw-r--
umask 0002

# turn on core dumps
ulimit -c unlimited

# who has a local mail spool these days?
unset MAILCHECK

# set a sane locale if not done yet
: ${LANG:="en_US.UTF-8"}
: ${LANGUAGE:="en"}
: ${LC_CTYPE:="en_US.UTF-8"}
: ${LC_ALL:="en_US.UTF-8"}
export LANG LANGUAGE LC_CTYPE LC_ALL

export SHELL=$(which bash)

# translate funky terminals into something more normal
tput -T $TERM colors 2>&1 >/dev/null ||
  export TERM=xterm

# load functions
source "${BASH_CONF}/func.sh"

: ${MANPATH=$(manpath 2>/dev/null)}

# Work around 0644 forced permissions from ::admin::user's File['/home/$USER']
# Taken from Ori's .bash_profile script. See
# I6bd9be8a946fef97df4b1f759a50afb59561ae15 for a nicer fix.
rsync --delete --recursive --chmod=u+x ${HOME}/.bin/ ${HOME}/bin &>/dev/null

# add common directories with bin,man,info,lib parts
add_root_dir "${HOME}"

# load interactive shell config if appropriate
[[ "$-" == *i* ]] && source_file ${BASH_CONF}/interactive.sh

# vim:sw=2 ts=2 sts=2 et ft=sh:
