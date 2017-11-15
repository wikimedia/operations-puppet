# Use .bashrc
[[ -r ~/.bashrc ]] && . ~/.bashrc

#Add my bin to path
export PATH=$PATH:$HOME/bin

#Aliases
alias sync-file='scap sync-file'
alias sync-dir='scap sync-dir'
alias mwversionsinuse='scap wikiversions-inuse'
alias ..='cd ..'
alias ll='ls -l --color=auto'