#!/usr/bin/env bash

export ACK_PAGER_COLOR="${PAGER:-less -R}"

alias ackcat="ack --passthru $@"
alias thpppt="ack --thpppt"

# muscle memory alias. I used to have custom recusive grep script named rgrep.
alias rgrep='ack'
