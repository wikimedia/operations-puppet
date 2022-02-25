case "$TERM" in
	xterm-256color)
		GIT_PS1_SHOWUNTRACKEDFILES=1
		GIT_PS1_SHOWDIRTYSTATE=1
		GIT_PS1_SHOWUPSTREAM="auto verbose"
		. /etc/bash_completion.d/git-prompt

		TITLEBAR='\[\e]0;\u@\h \w\007\]'
		PROMPT='\[\033[00;33m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)") \$ '
		PS1="$TITLEBAR$PROMPT"
		;;
	*)
		;;
esac

alias ls="ls --color"
alias grep="grep --color"

alias g="git"
. /usr/share/bash-completion/completions/git
__git_complete g __git_main

alias os="sudo wmcs-openstack"
