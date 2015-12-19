# Use .bashrc
[[ -r ~/.bashrc ]] && . ~/.bashrc

# HHVM goes insane without this (guess that's because some of my LC_* vars are de_DE.UTF-8)
export LC_ALL=en_US.UTF-8

# Aliases
alias ..='cd ..'
