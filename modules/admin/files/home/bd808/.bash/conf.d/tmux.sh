#!/usr/bin/env bash

builtin hash tmux &>/dev/null && {
  alias t=tmux
  attach () {
    if [[ "$*" ]]; then
      ssh "$*" -t 'tmux attach || tmux new'
    else
      tmux attach || tmux new
    fi
  }
  complete -F _known_hosts attach
}
