#!/usr/bin/env bash

[[ -d "${HOME}/.phpenv" ]] &&
add_root_dir "${HOME}/.phpenv"

builtin hash phpenv &>/dev/null && eval "$(phpenv init -)"
