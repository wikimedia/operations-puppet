#!/bin/bash

#
# File permissions
#
rsync --delete --recursive --chmod=u+x ~/.binned/ ~/.bin >/dev/null 2>&1


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
export HISTCONTROL="ignoreboth" HISTFILESIZE=2000 HISTSIZE=1000
export BLOCKSIZE=1024 CLICOLOR=1
export PS1='\[$BRIGHT\]\[$BLACK\][\[$HOSTCOLOR\]${HOSTNAME}\[$GREY\]:\[$RESET\]\[$GREY\]\w\[$BRIGHT\]\[$BLACK\]]\[$RESET\] $ '
export PATH="${PATH}:${HOME}/.bin"
export DEBFULLNAME="Ori Livneh" DEBEMAIL="ori@wikimedia.org"
export PYTHONSTARTUP="${HOME}/.pythonrc"
export PROMPT_COMMAND="history -a; history -n"
export HHVM="$(pidof -s /usr/bin/hhvm 2>/dev/null)"



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

alias ls="ls --color" ....="cd ../.." ...="cd .." cd..="cd .." g="git"
=()          { py "$*"; }
mkpass()     { head -c 32 /dev/urandom | base64 | tr -cd [:alnum:]; }
puppet()     { sudo puppet "$@"; }
warn()       { printf "$(tput setaf 1)%s$(tput sgr0)\n" "$1" >&2; }
notice()     { printf "$(tput setaf 4)%s$(tput sgr0)\n" "$1"; }
repackage()  { sudo dpkg-buildpackage -b -uc; }
psmem()      { sudo "$HOME/.bin/ps_mem.py" "${@}"; }
where()      { find . -iname \*"$*"\* ; }
reqs()       { curl -s 127.0.0.1/server-status | grep -Po '\d+(?= requests currently being processed)'; }
perf()       { sudo perf "$@"; }
gdbh()       { sudo gdb -p "$(pidof -s hhvm)"; }
redis-cli()  { redis-cli -a "$(grep -Po '(?<=masterauth )\S+' /etc/redis/redis.conf)" "$@"; }

ptop()       {
  args=( top )
  [[ -z $1 || $1 == -* ]] || { args+=( -p "$(pidof -s $1)" ); shift; }
  sudo perf "${args[@]}" "$@"
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

