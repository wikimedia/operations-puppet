case "$TERM" in
	xterm-256color)
		PS1='\[\033[00;33m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \$ '
		;;
	*)
		;;
esac

alias ls="ls --color"
alias g="git"
