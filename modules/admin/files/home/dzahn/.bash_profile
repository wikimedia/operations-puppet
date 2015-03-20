puppet()     { sudo puppet "$@"; }
alias ls="ls -hals"
alias tulpen="netstat -tulpen"
export VISUAL="vim" EDITOR="vim"
export DEBFULLNAME="Daniel Zahn" DEBEMAIL="dzahn@wikimedia.org"

RESET="$(tput sgr0)"
BRIGHT="$(tput bold)"
GREY="$(tput setaf 7)"
BLACK="$(tput setaf 0)"
HOSTCOLOR="$(tput setaf $(($(cksum<<<$HOSTNAME|cut -d' ' -f-1)%6+1)))"

export PS1='\[$BRIGHT\]\[$BLACK\][\[$HOSTCOLOR\]${HOSTNAME}\[$GREY\]:\[$RESET\]\[$GREY\]\w\[$BRIGHT\]\[$BLACK\]]\[$RESET\] $ '

