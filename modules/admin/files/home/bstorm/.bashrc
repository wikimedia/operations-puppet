# If not running interactively, don't do anything
[ -z "$PS1" ] && return

if [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi
#enable tab completion while as root
complete -cf sudo

#prevent overwriting files with pipe or cat
set -o noclobber

ulimit -c unlimited
unset MAILCHECK
alias pt="sudo -i puppet agent -t"

alias ls='ls --color=auto -F'
alias tree='tree -Csu'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
export PS1="\[\e[31m\][\[\e[m\]\u\[\e[31m\]@\[\e[m\]\[\e[36m\]\h\[\e[m\]\[\e[31m\]]\[\e[m\]\[\e[31m\]:\[\e[m\]\[\e[31m\]\W\[\e[m\] \[\e[31m\]\\$\[\e[m\] "
