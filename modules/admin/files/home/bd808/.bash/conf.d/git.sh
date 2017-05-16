#!/usr/bin/env bash

builtin hash git &>/dev/null && {
  alias g='git'
  alias gti='git'
  alias gexec='git exec'

  export GIT_EDITOR=${EDITOR}
  export GIT_MERGE_AUTOEDIT=no

  # from http://jeetworks.org/node/52
  gcd () {
    STATUS=$(git status 2>/dev/null)
    [[ -z $STATUS ]] && return
    cd "./$(git rev-parse --show-cdup)${1}"
  }
  _gcd () {
    STATUS=$(git status 2>/dev/null)
    [[ -z $STATUS ]] && return
    TARGET="./$(git rev-parse --show-cdup)"
    [[ -d $TARGET ]] && TARGET="${TARGET}/"

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}$2"
    dirs=$(cd $TARGET; compgen -o dirnames $2)
    opts=$(for i in $dirs; do if [[ $i != ".git" ]]; then echo $i/; fi; done)
    if [[ ${cur} == * ]] ; then
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      return 0
    fi
  }
  complete -o nospace -F _gcd gcd
}
