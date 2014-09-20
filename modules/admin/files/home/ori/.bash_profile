#!/bin/bash

#
# File permissions
#

chmod -f u+x ~/.bin/*


#
# Colors
#

RESET="$(tput sgr0)"
BRIGHT="$(tput bold)"
GREY="$(tput setaf 7)"
BLACK="$(tput setaf 0)"
HOSTCOLOR="$(tput setaf $(($(cksum<<<$HOSTNAME|cut -d' ' -f-1)%6+1)))"


#
# Exports
#

export VISUAL="vim" EDITOR="vim" TERM="xterm-256color"
export LC_ALL="en_US.UTF-8" LANG="en_US"
export HISTCONTROL="ignoredups" HISTFILESIZE=2000 HISTSIZE=1000
export BLOCKSIZE=1024 CLICOLOR=1
export PS1='\[$BRIGHT\]\[$BLACK\][\[$HOSTCOLOR\]${HOSTNAME}\[$GREY\]:\[$RESET\]\[$GREY\]\w\[$BRIGHT\]\[$BLACK\]]\[$RESET\] $ '
export PATH="${PATH}:${HOME}/.bin"


#
# Shell options
#

umask 002
set -o noclobber
shopt -s autocd cdable_vars cdspell checkwinsize \
    cmdhist dirspell dotglob extglob globstar histappend \
    lastpipe no_empty_cmd_completion nocaseglob 2>/dev/null


#
# Shortcuts
#

alias ls="ls --color" ...="cd .." cd..="cd .." g="git"
=()          { py "$*"; }
mkpass()     { head -c 32 /dev/urandom | base64 | tr -cd [:alnum:]; }
puppet-run() { sudo puppet agent -tv; }
puppetd()    { sudo puppt-agent "${@}"; }
warn()       { printf "$(tput setaf 1)%s$(tput sgr0)\n" "$1" >&2; }
notice()     { printf "$(tput setaf 4)%s$(tput sgr0)\n" "$1"; }
localcurl()  {
  for var; do [[ $var == */* ]] && url="${var#*//}" || args+=("$var"); done
  curl -H "host: ${url%%/*}" "${args[@]}" "localhost/${url#*/}"
}


#
# z - https://github.com/rupa/z
#

_Z_OWNER="ori"
. "${HOME}/.z.sh"


#
# Host-specific profile
#

if [ -r "${HOME}/.hosts/${HOSTNAME}" ]; then
  . "${HOME}/.hosts/${HOSTNAME}"
fi

