# ~/.bashrc: executed by bash(1) for non-login shells.

# Prompt
export PS1="\[\033[48;5;1m\]\[\033[01;37m\] \h \[\033[00m\] \[\033[01;37m\]\$?\[\033[00m\] \[\033[01;36m\]\w\[\033[00m\]\$ "

# Safe aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Useful aliases
alias top='top -cd 1'
alias free='free -m'
alias my='sudo mysql --defaults-file=/root/.my.cnf'

# ls aliases
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lAhrt'
alias l='ls $LS_OPTIONS -lAh'

# Bash history
export HISTCONTROL=erasedups
export HISTSIZE=30000
export HISTFILESIZE=50000
shopt -s histappend
