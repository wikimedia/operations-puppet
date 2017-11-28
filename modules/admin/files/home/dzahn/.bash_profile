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

alias pa="sudo puppet agent -tv"

alias cachemiscpuppet="sudo cumin -b 3 -s 10 'R:class = role::cache::misc' 'run-puppet-agent -q'"

# set the right base dir for reprepro, depending whether it's apt.wm.org or releases.wm.org
if [ "$(hostname -s | cut -c 1-8)" == "releases" ]; then
    export REPREPRO_BASE_DIR=/srv/org/wikimedia/reprepro
fi
if [ "$(hostname -s | cut -c 1-7)" == "install" ]; then
    export REPREPRO_BASE_DIR=/srv/wikimedia
fi

