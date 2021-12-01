case "$TERM" in
	xterm-256color)
		GIT_PS1_SHOWUNTRACKEDFILES=1
		GIT_PS1_SHOWDIRTYSTATE=1
		GIT_PS1_SHOWUPSTREAM="auto verbose"
		. /etc/bash_completion.d/git-prompt

		PS1='\[\033[00;33m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)") \$ '
		;;
	*)
		;;
esac

alias ls="ls --color"
alias g="git"

alias os="sudo wmcs-openstack"
