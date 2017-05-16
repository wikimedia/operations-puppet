#!/usr/bin/env bash
# vi improved

if builtin hash vim &>/dev/null ; then
  # don't talk to x server
  alias vim='vim -X'

  # use my vimrc from other accounts
  [[ "${BASH_CONF}" != "${HOME}/.bash" ]] &&
  alias vim="vim -X -u ${BASH_CONF}/../.vimrc -i ~/.viminfo"

else
  # muscle memory is hard to break
  alias vim='vi'

fi

alias e='vim'
alias bim='vim'
alias gim='vim'

# vim:sw=2 ts=2 sts=2 et ft=sh:
