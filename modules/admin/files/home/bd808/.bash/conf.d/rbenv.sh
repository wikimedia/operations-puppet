#!/usr/bin/env bash

[[ -d "${HOME}/.rbenv" ]] &&
add_root_dir "${HOME}/.rbenv"

builtin hash rbenv &>/dev/null && eval "$(rbenv init -)"
