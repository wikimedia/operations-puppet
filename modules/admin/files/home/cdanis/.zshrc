# Set up the prompt
autoload -Uz add-zsh-hook
. ~/.zshfunc/prompt_cdanis1_setup

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep a jillion lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt appendhistory
setopt incappendhistory
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_space

# slashes are words.
WORDCHARS=${WORDCHARS/\/}

# some hooks for xterm for now
# TODO: screen/tmux
function xterm_precmd() {
    print -Pn "\e]0;%n@%m %~\a"
}

function xterm_preexec() {
    print -Pn '\e]0;%n@%m %# ' && print -n "${(q)1}\a"
}

if [[ $TERM == (xterm*) ]]; then
    add-zsh-hook -Uz precmd xterm_precmd
    add-zsh-hook -Uz preexec xterm_preexec
fi

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

zstyle ':completion:*:hosts' known-hosts-files /home/cdanis/.ssh/known_hosts /home/cdanis/.ssh/known_hosts.d/wmf-cloud /home/cdanis/.ssh/known_hosts.d/wmf-prod
