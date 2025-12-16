# Source system's bashrc
if [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

### ALIASES

alias ls='ls --color=auto -F'
alias ll='ls -l'
alias tree='tree -ACF'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Took me a decade until I suddenly thought about those:
alias good='git bisect good'
alias bad='git bisect bad'

# cal starts the week with Sunday
# ncal is a confusing transposed calendar. -b flips it
alias cal='ncal -b'

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

if [ -v STY ]; then
    _short_socket_name=${STY%."$(hostname)"}
    PS1="(\[\033[01;36m\]$_short_socket_name\[\033[00m\]) $PS1"
    unset _short_socket_name
fi
