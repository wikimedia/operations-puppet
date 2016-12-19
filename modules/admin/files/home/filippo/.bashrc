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

alias pat='sudo puppet agent --test'

webproxy_url="http://webproxy.eqiad.wmnet:8080"
export no_proxy=".wmnet"
alias proxy-on="export http_proxy=$webproxy_url https_proxy=$webproxy_url"
alias proxy-off="unset http_proxy https_proxy"

function config_interactive() {
    RESET="$(tput sgr0)"
    BRIGHT="$(tput bold)"
    RED="$(tput setaf 1)"
    WHITE="$(tput setaf 7)"
    export PS1='\[$BRIGHT\]\[$RED\]\h\[$RESET\]:\w\[$BRIGHT\]\[$WHITE\]\$\[$RESET\] '
}

if [ -n "$PS1" ]; then
    config_interactive
fi
