# keep the matching/ordering of grep and friends sane
export LC_COLLATE=C
# quit on one screen, interpret color escape, do not clear screen
export LESS=FRX

# history settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=5000
HISTTIMEFORMAT="%FT%TZ "
shopt -s histappend

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

RESET="$(tput sgr0)"
BRIGHT="$(tput bold)"
RED="$(tput setaf 1)"
WHITE="$(tput setaf 7)"
export PS1='\[$BRIGHT\]\[$RED\]\h\[$RESET\]:\w\[$BRIGHT\]\[$WHITE\]\$\[$RESET\] '
