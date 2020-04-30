# ~/.bashrc: executed by bash(1) for non-login shells.

# Set up paths, regardless of the type of shell.
pathmunge () {
    [ -d "$2" ] || return
    if ! echo ${!1} | egrep -q "(^|:)$2($|:)"; then
        if [ -n "${!1}" ]; then
            declare -g $1=$2:${!1}
        else
            declare -g $1=$2
        fi
    fi
}
UNSETTODO+=" pathmunge"
pathmunge PATH /usr/local/go/bin
pathmunge PATH ~/.local/bin
pathmunge PATH ~/go/bin
pathmunge PATH ~/opt/bin
pathmunge PATH ~/bin
pathmunge PATH /usr/local/sbin
pathmunge PATH /usr/sbin
pathmunge PATH /sbin

# If not running interactively, stop here
case $- in
    *i*) ;;
      *) return;;
esac

# History
# Ignore duplicate commands
export HISTCONTROL=ignoredups
# Save decent amounts of history
export HISTSIZE=10000
export HISTFILESIZE=10000
# Add timestamp to history
export HISTTIMEFORMAT="%Y-%m-%dT%H:%M:%S%z "
# Save multi-line commands into a single history entry, for easier editing.
export cmdhist=on
# Perform history substitions on ^M, but don't run the command
shopt -qs histverify
# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
# Use 256color xterm if appropriate and supported.
if [ "$TERM" = "xterm" ]; then
    tput -T xterm-256color longname &>/dev/null && export TERM=xterm-256color
fi

# Contains everything that needs to be unset at the end.
UNSETTODO=

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

if [ -n "$(type -P nvim)" ]; then
    export EDITOR=nvim
    export VISUAL="$EDITOR"
    alias vi="nvim"
elif [ -n "$(type -P vim)" ]; then
    export EDITOR=vim
    export VISUAL="$EDITOR"
    alias vi="vim -N"
fi

if [ -n "$(type -P less)" ]; then
    export PAGER=less
    export GIT_PAGER="less -i -R -X -F"
    export LESS="-i -R -X"
fi

alias grep='grep --color=auto'
alias grepc='grep --color=always'
alias jobs="jobs -l"
alias xo='xdg-open'

# Source bash functions
. ~/.bashfuncs

promptsetup

if [ -f ~/.bashrc.local ]; then
    . ~/.bashrc.local
fi

# Unset vars/functions that aren't needed anymore
for i in $UNSETTODO; do
    unset $i
done
unset UNSETTODO

# vim:ft=sh
