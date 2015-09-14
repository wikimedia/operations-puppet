# .bashrc
function proml {
	local NO_COLOUR="\[\033[0m\]"
	local BLACK="\[\033[0;30m\]"
	local RED="\[\033[0;31m\]"
	local GREEN="\[\033[0;32m\]"
	local BROWN="\[\033[0;33m\]"
	local BLUE="\[\033[0;34m\]"
	local PURPLE="\[\033[0;35m\]"
	local CYAN="\[\033[0;36m\]"
	local LIGHT_GRAY="\[\033[0;37m\]"

	local DARK_GRAY="\[\033[1;30m\]"
	local LIGHT_RED="\[\033[1;31m\]"
	local LIGHT_GREEN="\[\033[1;32m\]"
	local YELLOW="\[\033[1;33m\]"
	local LIGHT_BLUE="\[\033[1;34m\]"
	local LIGHT_PURPLE="\[\033[1;35m\]"
	local LIGHT_CYAN="\[\033[1;36m\]"
	local WHITE="\[\033[1;37m\]"

	case $TERM in
	xterm*|rxvt*)
		TITLEBAR='\[\033]0;\u@\h:\w\007\]'
		;;
	*)
		TITLEBAR=""
		;;
	esac

	local BRACKETS CLOCK MAINCOL DOLLAR
	BRACKETS=$BLUE
	CLOCK=$RED
	MAINCOL=$LIGHT_RED
	DOLLAR=$DARK_GRAY
	
	PS1="${TITLEBAR}$BRACKETS[$CLOCK\$(date +%H%M)$BRACKETS][$MAINCOL\u@\h:\w$BRACKETS]$DOLLAR\$$NO_COLOUR "
	PS2="$DOLLAR>$NO_COLOUR "
	PS4="$DOLLAR+$NO_COLOUR "
}

# User specific aliases and functions
alias ls="ls --color=tty"
alias ll="ls -l -h"

if [ "$PS1" ]; then
	proml
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

umask 002
export CVS_RSH=ssh
export CVSROOT=:ext:timstarling@cvs.sourceforge.net/cvsroot/wikipedia
export RSYNC_RSH=ssh
export RCMD_CMD=ssh
export FANOUT=20
export EDITOR=vim

if [ -e /usr/local/lib/mw-deployment-vars.sh ]; then
	. /usr/local/lib/mw-deployment-vars.sh
	export ENWIKI_VERSION=$(php -r '$a = json_decode(file_get_contents("/srv/mediawiki-staging/wikiversions.json")); print $a->enwiki;')
	if [ -e $MEDIAWIKI_STAGING_DIR ]; then
		export WIKI=$MEDIAWIKI_STAGING_DIR/$ENWIKI_VERSION
	else
		export WIKI=$MEDIAWIKI_DEPLOYMENT_DIR/$ENWIKI_VERSION
	fi
fi

function cdp() {
	local dir
	case "$1" in
		c)
			dir=$WIKI/../wmf-config
			;;
		i)
			dir=$WIKI/includes
			;;
		e)
			dir=$WIKI/extensions
			;;
		l)
			dir=$WIKI/languages
			;;
		m)
			dir=$WIKI/maintenance
			;;
		*)
			dir="$WIKI/$1"
	esac
	if [ ! -z "$2" ]; then
		dir="$dir/$2"
	fi
	cd $dir
}

function cvsd() {
	cvs -d$CVSROOT "$@"
}

alias sshauth="export SSH_AUTH_SOCK=~/.stuff"
alias sshp="ssh -o PasswordAuthentication=yes"
alias ack=ack-grep
alias dshroot="dsh -o-oUser=root"
alias tawk='awk -F'\''	'\'''

function genpass() {
	tr -cd [:alnum:] < /dev/urandom | head -c10
	echo
}

