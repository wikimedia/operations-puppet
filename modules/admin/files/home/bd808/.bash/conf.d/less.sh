#!/usr/bin/env bash
# less is better than more!

# -F auto quit if it fits on screen
# -i search case-insensitive
# -Q no bells!
# -R ansi color support
# -w flash the first new line that scrools in
# -X don't clear screen on quit
export LESS='-FiQRwX'

# don't track history
export LESSHISTFILE='-'

# make less more friendly for non-text input files, see lesspipe(1)
builtin hash lesspipe &>/dev/null && eval "$(lesspipe)"

export PAGER='less'

# -s collapse multiple bank lines
export MANPAGER='less -s'

# Less Colors for Man Pages
export LESS_TERMCAP_mb=$'\E[0;32m' # begin blinking
export LESS_TERMCAP_md=$'\E[0;32m' # begin bold
export LESS_TERMCAP_me=$'\E[0m'    # end mode
export LESS_TERMCAP_se=$'\E[0m'    # end standout-mode
export LESS_TERMCAP_so=$'\E[4m'    # begin standout-mode - info box
export LESS_TERMCAP_ue=$'\E[0m'    # end underline
export LESS_TERMCAP_us=$'\E[0;33m' # begin underline

# vim:sw=2 ts=2 sts=2 et ft=sh:
