#!/bin/bash
# Source system's bashrc
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups
# ... and ignore same sucessive entries.
export HISTCONTROL=ignoreboth

# If this is an xterm set the title to user@host:dir
case "$TERM" in
    xterm*|rxvt*)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
        ;;
    *)
        ;;
esac

# Set up colored prompt if in a terminal that supports colors, or
# Use the Debian standard.
#
case "$TERM" in
    xterm-256color)
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ';;
    *)
    ;;
esac

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Host-specific entries
# use non-numbered part of the hostname
__hostbase=${HOSTNAME//[[:digit:]]/}
if [ -r "${HOME}/.hosts/${__hostbase}" ]; then
    . "${HOME}/.hosts/${__hostbase}"
fi

# Aliases
alias set_proxy="export http_proxy=http://webproxy.eqiad.wmnet:8080; export HTTPS_PROXY=http://webproxy.eqiad.wmnet:8080;"
alias pdisable="sudo disable-puppet $@"
alias penable="sudo enable-puppet $@"
alias prun="sudo run-puppet-agent"
alias please="sudo !!"

# Set envoy runtime values on a physical host.
function envoy-runtime-set {
    curl -X POST "http://localhost:9631/runtime_modify?${1}=${2}"
}

function gitroot() {
    cd "$(git rev-parse --show-toplevel)" || return
}

# Docker-related shortcuts. Only defined if docker is present.
if command -v docker > /dev/null; then
    debian-shell() {
        DISTRO=${1:-buster}
        shift
        docker run --rm -ti "$@" docker-registry.discovery.wmnet/$DISTRO:latest /bin/bash
    }

    docker-root-shell() {
        IMG=${1}
        if [ -n "$IMG" ]; then
            docker run --rm -ti --user root --entrypoint /bin/bash "docker-registry.discovery.wmnet/$IMG"
        else
            echo "usage: docker-root-shell IMAGE:TAG"
            return 1
        fi
    }
fi

# Kafkacat-related shortcuts.
if command -v kafkacat > /dev/null; then
    kafkaread() {
        TOPIC=$1
        if [ ! -n "$TOPIC" ]; then
            echo "usage: kafkaread <topic>";
        fi
        kafkacat -C -b "$(hostname -f)":9093 -t "$TOPIC" -X security.protocol=SSL
    }
fi
