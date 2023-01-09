# Source system's bashrc
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

### ALIASES

alias ls="ls --color=auto -F"
alias ll="ls -l"

### MISC SETTINGS

# Disable systemd pager which is REALLY annoying
export SYSTEMD_PAGER=''

### Bash history tweaking

# append to history instead of overwriting
shopt -s histappend
HISTCONTROL=ignoredups:ignorespace
HISTFILESIZE=19119
HISTSIZE=1911  # 0x777
HISTIGNORE=ls:ll:cd
HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S %z | '
