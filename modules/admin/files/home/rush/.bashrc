# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# append to the history file, don't overwrite it
shopt -s histappend
HISTFILESIZE=2500
# no duplicate entries
export HISTCONTROL=ignoreboth:erasedups
# append history file
shopt -s histappend
export HISTIGNORE='ls:pwd:date:cd:u:uu:uuu:uuuu:uuuuu:ls:ls -al'

# update histfile after every comman
export PROMPT_COMMAND="history -a"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1="\[\033[01;33m\]\w\[\033[00m\]"
    PS2="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]>"
else
    PS2=""
    PS2="${debian_chroot:+($debian_chroot)}\u@\h:\w\$ "
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

unset color_prompt force_color_prompt

#handle OSX cases
OS=$(uname)
if [ "$OS" == "Darwin" ];
    then
    alias ls="ls -GFh"
    alias grep="grep --color='auto'"
fi

if [ -z "$PROMPT_COMMAND" ]; then
    PREV_CMD=
else
  if [ "$OS" == "Darwin" ];
    then
      #fuck you bash: update_terminal_cwd: command not found
      PREV_CMD=
    else
      PREV_CMD="${PROMPT_COMMAND}; "
  fi
fi

PROMPT_COMMAND="${PREV_CMD}"'if [ -z "${_PS1_ORIG}" ]; then
                    export _PS1_ORIG=$PS1;
                fi;
                if [ -e ~/bin/prompt.sh ]; then
                    export _PS1="\$(~/bin/prompt.sh)";
                fi;

                PS1="\n${_PS1_ORIG}\n${_PS1}${PS2}"'

export PROMPT_COMMAND

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# Alias  and function definitions
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# for work specific stuff
if [ -f ~/.bash_workcommands ]; then
    . ~/.bash_workcommands
fi

# for git specific stuff
if [ -f ~/.bash_git ]; then
    . ~/.bash_git
fi

# enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

if [ "$OS" == "Darwin" ];
  then
    if [ -f $(brew --prefix)/etc/bash_completion ]; then
      . $(brew --prefix)/etc/bash_completion
  fi
fi

COLOR1="\[\033[0;36m\]"
COLOR2="\[\033[1;32m\]"
COLOR3="\[\033[0;36m\]"
COLOR4="\[\033[0;37m\]"
COLOR5="\[\033[1;33m\]"
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

if [ "$UID" = "0" ];
  then
    COLOR2="\[\033[1;31m\]"
fi
