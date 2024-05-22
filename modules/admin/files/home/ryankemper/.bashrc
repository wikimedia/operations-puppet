# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

alias tls='tmux ls'
alias tns='tmux new -s'
alias tks='tmux kill-session -t'
alias tat='tmux attach -t'

# Intended to reduce vim escape-key delay
# (10ms for key sequences)
# Source: https://www.johnhawthorn.com/2012/09/vi-escape-delays/
export KEYTIMEOUT=1


# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# append to the history file, don't overwrite it
shopt -s histappend
# Write history on every opportunity
export PROMPT_COMMAND='history -a; history -r'
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
