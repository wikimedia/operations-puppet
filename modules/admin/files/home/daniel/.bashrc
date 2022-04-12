# ~/.profile: executed when starting a new shell.

# my path
export PATH=$PATH:~/bin

# don't log me out on ctrl-d
set -o ignoreeof

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# aliases
alias l=ls
alias ll="ls -l"
alias la="ls -a"
alias ..="cd .."
alias ...="cd ../.."

# nice primpt with git info
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUPSTREAM="auto verbose"
. /etc/bash_completion.d/git-prompt
#PS1='[\u@\h \w$(__git_ps1 " (%s)")]\$ '
#PS1='\[\033[01;34m\]\D{%H:%M} [\u@\h \w$(__git_ps1 " (%s)")]\$\[\033[0m\] '
PS1='\[\033[01;34m\]\D{%H:%M} \[\033[01;31m\]\u@\h\[\033[01;32m\]$(__git_ps1 " [%s]") \[\033[01;34m\]\w>\[\033[0m\]'

# set proxy variables
export HTTP_PROXY=http://webproxy:8080
export HTTPS_PROXY=http://webproxy:8080
export http_proxy=http://webproxy:8080
export https_proxy=http://webproxy:8080
export NO_PROXY=127.0.0.1,::1,localhost,.wmnet
export no_proxy=127.0.0.1,::1,localhost,.wmnet,