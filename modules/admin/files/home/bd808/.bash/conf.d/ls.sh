#!/usr/bin/env bash

# load precompiled color constants
source_file "${BASH_CONF}/ls_colors"
export CLICOLOR=1

alias ls='command ls -bFGh'
$(ls --help 2>&1 | grep -- --color= &>/dev/null) && {
  alias ls='command ls -bCF --color=auto'
}

alias ll='ls -l'
alias lsa='ls -a'
alias lld='ll -d'
alias l.='ls -d .*'

