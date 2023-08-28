export EDITOR=vim
export VISUAL=vim

alias ls="ls --color=auto"
alias l="ls --color=auto"
alias ll="ls --color=auto -al"
alias less="less -R"
alias vi="vim"
alias grep="grep --color"

# Append, don't overwrite history file
# Automatically resize text when resizing the window.
shopt -s histappend checkwinsize
HISTCONTROL=ignoredups:erasedups:ignorespace

# If not running interactively, the rest of this file will only hinder
[[ $- != *i* ]] && return

# Disable ^S for hiding/queuing keyboard inputs and ^Q for putting the
# queued inputs. Just some stupid features I'll never ever need.
stty -ixon

# Color-code the different modes I can be in.
nocolor=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
gray=$(tput setaf 8)
blue=$(tput setaf 12)

# Do we have git completion installed? If so, use it.
if [[ -f /usr/share/git/completion/git-prompt.sh ]]; then
    . /usr/share/git/completion/git-prompt.sh
    export GIT_PS1_SHOWDIRTYSTATE=1
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWSTASHSTATE=1
    # Common components all modes should have
    PS1='\[$blue\]$(__git_ps1 "[%s]")\[$nocolor\]'
else
    PS1=''
fi

# Prepend an indicator when running a sub-shell in a program
[[ $VIM ]] || [[ $NVIM_LISTEN_ADDRESS ]] && PS1="\[$gray\][vi]\[$nocolor\]$PS1"

# Remote host? Display user@hostname:path for easy copy for scp
if [[ -n "${SSH_CLIENT}" || -n "${SSH_TTY}" || "$EUID" == 0 ]] ; then
    if [[ "$EUID" == 0 ]]; then
        PS1="${PS1}[\[$red\]\u\[$nocolor\]@\h:\w]"
    else
        PS1="${PS1}[\u@\h:\w]"
    fi
else
    PS1="${PS1}[\w]"
fi

if [[ "$EUID" == 0 ]]; then
    # Red hash to denote root
    PS1="$PS1\[$red\]# \[$nocolor\]"
else
    PS1="$PS1$ "
fi
