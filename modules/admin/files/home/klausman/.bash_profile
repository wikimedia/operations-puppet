# bash_profile
#
# shellcheck shell=bash

PATH="$HOME/bin:$HOME/.local/bin:$PATH:/sbin:/usr/sbin"
export PATH
unset USERNAME

if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
fi
case "${TERM}" in
    screen*|tmux*)
        unset DISPLAY
        ;;
esac

# I would like a 24h clock, ty
export LC_TIME=C

# vim: ft=sh expandtab tabstop=4 smarttab
