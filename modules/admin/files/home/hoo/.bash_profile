# Use .bashrc
[[ -r ~/.bashrc ]] && . ~/.bashrc

# HHVM goes insane without this (guess that's because some of my LC_* vars are de_DE.UTF-8)
export LC_ALL=en_US.UTF-8

# Aliases
alias ..='cd ..'
alias ll='ls -l --color=auto'

function http_proxy_set {
	export http_proxy=http://webproxy.eqiad.wmnet:8080
	export https_proxy=http://webproxy.eqiad.wmnet:8080
	export no_proxy=127.0.0.1,localhost,.wmnet
}

alias https_proxy_set='http_proxy_set'
