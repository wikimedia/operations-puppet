autoload -Uz promptinit
promptinit
autoload -Uz compinit
compinit
autoload -U up-line-or-search
autoload -U down-line-or-search

bindkey -e
bindkey "${terminfo[kcud1]}" down-line-or-search
bindkey "${terminfo[kcuu1]}" up-line-or-search

PROMPT='%F{cyan}%m%f %F{green}%2~%f %(?.%F{green}.%F{red})%#%f '
RPROMPT='[%F{yellow}%*%f]'

setopt histignorealldups sharehistory

# Keep a jillion lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_minus
setopt hist_ignore_dups
setopt hist_reduce_blanks
setopt inc_append_history
setopt auto_cd

# slashes are words.
WORDCHARS=${WORDCHARS/\/}

eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

### Functions imported from oh-my-ssh

# ------------------------------------------------------------------------------
# Description
# -----------
#
# sudo or sudoedit will be inserted before the command
#
# ------------------------------------------------------------------------------
# Authors
# -------
#
# * Dongweiming <ciici123@gmail.com>
#
# ------------------------------------------------------------------------------

sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == $EDITOR\ * ]]; then
        LBUFFER="${LBUFFER#$EDITOR }"
        LBUFFER="sudoedit $LBUFFER"
    elif [[ $BUFFER == sudoedit\ * ]]; then
        LBUFFER="${LBUFFER#sudoedit }"
        LBUFFER="$EDITOR $LBUFFER"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
function set_proxy {
  export HTTP_PROXY=http://webproxy:8080
  export HTTPS_PROXY=http://webproxy:8080
  export http_proxy=http://webproxy:8080
  export https_proxy=http://webproxy:8080
  export NO_PROXY=127.0.0.1,::1,localhost,.wmnet,.wikimedia.org
  export no_proxy=127.0.0.1,::1,localhost,.wmnet,.wikimedia.org
}

function clear_proxy {
  unset HTTP_PROXY
  unset HTTPS_PROXY
  unset http_proxy
  unset https_proxy
  unset NO_PROXY
  unset no_proxy
}
function s_client {
  openssl s_client -connect ${1:-localhost:443}  < /dev/null |& openssl x509 -noout -text
}
if [ $commands[kubectl] ]
then
  source <(kubectl completion zsh)
fi
zle -N sudo-command-line
# Defined shortcut keys: [Esc] [Esc]
bindkey "\e\e" sudo-command-line

