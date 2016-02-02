hostname="$(hostname --fqdn)"
export PS1="\[\033]0;\u@${hostname}:\w\007\]${debian_chroot:+($debian_chroot)}\t \u@$hostname:\w\n\$ "

alias ls='ls --color=auto'
alias grep='grep --color=auto'
