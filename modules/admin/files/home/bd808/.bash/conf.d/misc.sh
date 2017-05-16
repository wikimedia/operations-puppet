#!/usr/bin/env bash

alias df='df -h'
alias du='du -h'
alias du1='du -h --max-depth=1'

alias bc='bc -l -q'
alias hd='od -Ax -tx1z -v'                    # hexdump
alias cal='cal -3'                            # show 3 months of calendars

alias whence='type -a'                        # where, of a sort

alias screen='screen -R -D'

alias psu='ps U $USER'

alias stardate='date "+%y%m.%d/%H%M"'

# vim:sw=2 ts=2 sts=2 et ft=sh:
