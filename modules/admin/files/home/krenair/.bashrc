alias ls='ls --color=auto'
alias grep='grep --color=auto'

[ -z "$PS1" ] && return

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[31m\]$(__git_ps1)\[\033[00m\]\$ '
