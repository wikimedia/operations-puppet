alias ls='ls --color=auto'
alias grep='grep --color=auto'
export EDITOR=nano
export SUDO_EDITOR=nano

[ -z "$PS1" ] && return

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
    PS1='\[\e]0;\u@\h:\w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '
fi
