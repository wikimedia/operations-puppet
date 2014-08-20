# keep the matching/ordering of grep and friends sane
export LC_COLLATE=C
# quit on one screen, interpret color escape, do not clear screen
export LESS=FRX

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

HISTCONTROL=ignoreboth
