#!/bin/bash

#
# File permissions
#
rsync --delete --recursive --chmod=u+x ~/.binned/ ~/.bin >/dev/null 2>&1


#
# Colors
#

BLACK="$(tput setaf 0)"
BRIGHT="$(tput bold)"
GREY58="$(tput setaf 246)"
GREY="$(tput setaf 7)"
LIGHTSTEELBLUE3="$(tput setaf 146)"
RED="$(tput setaf 1)"
RESET="$(tput sgr0)"
SKYBLUE3="$(tput setaf 74)"
UNDERLINE="$(tput smul)"
HOSTCOLOR="$(tput setaf $(($(cksum<<<$HOSTNAME|cut -d' ' -f-1)%6+1)))"


#
# Exports
#

export VISUAL="vim" EDITOR="vim" TERM="xterm-256color"
export LC_ALL="en_US.UTF-8" LANG="en_US" LC_COLLATE="C"
export HISTCONTROL="ignoreboth" HISTFILESIZE=2000 HISTSIZE=1000
export BLOCKSIZE=1024 CLICOLOR=1
export PS1='\[$BRIGHT\]\[$BLACK\][\[$HOSTCOLOR\]${HOSTNAME}\[$GREY\]:\[$RESET\]\[$GREY\]\w\[$BRIGHT\]\[$BLACK\]]\[$RESET\] $ '
export PATH="${PATH}:${HOME}/.bin"
export DEBFULLNAME="Ori Livneh" DEBEMAIL="ori@wikimedia.org"
export PYTHONSTARTUP="${HOME}/.pythonrc"
export PROMPT_COMMAND="history -a; history -n"
export HHVM="$(pidof -s /usr/bin/hhvm 2>/dev/null)"
export LESS="FIKMQRX" GROFF_NO_SGR=1



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

alias ls="ls --color" ....="cd ../.." ...="cd .." cd..="cd .." g="git" doh='sudo $(fc -ln -1)'
=()          { py "$*"; }
mkpass()     { head -c 32 /dev/urandom | base64 | tr -cd [:alnum:]; }
puppet()     { sudo puppet "$@"; }
warn()       { printf "$(tput setaf 1)%s$(tput sgr0)\n" "$1" >&2; }
notice()     { printf "$(tput setaf 4)%s$(tput sgr0)\n" "$1"; }
repackage()  { sudo dpkg-buildpackage -b -uc; }
psmem()      { sudo "$HOME/.bin/ps_mem.py" "${@}"; }
where()      { find . -iname \*"$*"\* ; }
reqs()       {
  # Find the apache2 log file with the most recent mtime that isn't an error log.
  local log_file="$(sudo find /var/log/apache2 -type f -name '*.log' \
    -not -name '*error*' -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"
  sudo tail -f "$log_file" | pv -lraN "apache2 reqs/sec (current/average)" >/dev/null
}
service()    { sudo service "$@"; }
perf()       { sudo perf "$@"; }
gdbh()       { sudo gdb -p "$(pidof -s hhvm)"; }
redis-cli()  { command redis-cli -a "$(grep -Po '(?<=masterauth )\S+' /etc/redis/redis.conf)" "$@"; }
fields()     { tail -1 "${@:---}" | awk 'END { for (i = 1; i <= NF; i++) printf("%s : %s\n", i, $i) }'; }
field()      { local fieldnum="$1"; shift; awk -v field="$fieldnum" '{print $(field)}' "${@}"; }
lat()        { ls -lat *"${@:+.}${@}" | head; }
sudo()       { command sudo -E "$@"; }
hbnt()       { /usr/bin/comm -23 "$1" "$2"; } # Here but not there (lines in $1 that are not in $2)
bhat()       { /usr/bin/comm -12 "$1" "$2"; } # Both here and there (lines common to both $1 and $2)

cleanup()    {
  mkdir -p ~/old
  find ~ -type f \( ! -iname ".*" \) -maxdepth 1 -exec mv {} ~/old \;
}

ptop()       {
  args=( top )
  [[ -z $1 || $1 == -* ]] || { args+=( -p "$(pidof -s $1)" ); shift; }
  sudo perf "${args[@]}" "$@"
}

man() {
    env LESS_TERMCAP_mb="${BRIGHT}${RED}"                \
        LESS_TERMCAP_md="${BRIGHT}${SKYBLUE3}"           \
        LESS_TERMCAP_me="${RESET}"                       \
        LESS_TERMCAP_se="${RESET}"                       \
        LESS_TERMCAP_so="${GREY58}"                      \
        LESS_TERMCAP_ue="${RESET}"                       \
        LESS_TERMCAP_us="${UNDERLINE}${LIGHTSTEELBLUE3}" \
        man "$@"
}


#
# fasd - https://github.com/clvv/fasd
#
. .fasd_init


#
# Host-specific profile
#
if [ -r "${HOME}/.hosts/${HOSTNAME}" ]; then
  . "${HOME}/.hosts/${HOSTNAME}"
fi
