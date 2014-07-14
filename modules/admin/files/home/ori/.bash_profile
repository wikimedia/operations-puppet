#!/bin/bash


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

export VISUAL=vim EDITOR=vim TERM=xterm-256color
export LC_ALL="en_US.UTF-8" LANG="en_US"
export HISTCONTROL=ignoredups HISTFILESIZE=2000 HISTSIZE=1000
export BLOCKSIZE=1024 CLICOLOR=1
export PS1='\[$BRIGHT\]\[$BLACK\][\[$HOSTCOLOR\]${HOSTNAME}\[$GREY\]:\[$RESET\]\[$GREY\]\w\[$BRIGHT\]\[$BLACK\]]\[$RESET\] $ '


#
# Shell options
#

umask 002
set -o noclobber
shopt -s autocd cdable_vars cdspell checkwinsize \
    cmdhist dirspell dotglob extglob globstar histappend \
    lastpipe no_empty_cmd_completion nocaseglob


#
# Shortcuts
#

alias ls="ls --color" ...="cd .." cd..="cd .."
:()          { echo "$*" | python - ; }
mkpass()     { head -c 32 /dev/urandom | base64 | tr -cd [:alnum:]; }
puppet-run() { sudo puppet agent -tv; }
puppetd()    { sudo puppt-agent "${@}"; }


#
# Host-specific profile
#

if [ -r "${HOME}/.hosts/${HOSTNAME}" ]; then
  . "${HOME}/.hosts/${HOSTNAME}"
fi
