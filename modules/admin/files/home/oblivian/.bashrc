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
if [ -r "${HOME}/.hosts/${HOSTNAME}" ]; then
    . "${HOME}/.hosts/${HOSTNAME}"
fi

# Aliases
alias set_proxy="export http_proxy=http://webproxy.eqiad.wmnet:8080; export HTTPS_PROXY=http://webproxy.eqiad.wmnet:8080;"
alias pdisable="sudo puppet agent --disable $@"
alias penable="sudo puppet agent --enable"
alias prun="sudo puppet agent -tv"
alias please="sudo $(fc -ln -1)"
