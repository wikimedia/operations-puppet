# Set up the prompt
autoload -Uz add-zsh-hook
. ~/.zshfunc/prompt_cdanis1_setup

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# bind C-x C-e / C-x e to opening an editor for the current command
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

# Keep a jillion lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt appendhistory
setopt incappendhistory
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_space

WORDCHARS=${WORDCHARS/\/}  # slashes are words
WORDCHARS=${WORDCHARS/=}   # and so are equalses

# ISO8601 tab-delimited ts
function isotabts() {
    ts "%Y-%m-%dT%H:%M:%.S"$'\t'
}

function interarrivalts() {
    ts -i '%.S'$'\t'
}

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

function _on_wmf_prod() {
    [[ "$(hostname -f)" = *(wmnet|wikimedia.org) ]]
    return $?
}

if _on_wmf_prod ; then
    alias last-puppet-run='sudo /etc/update-motd.d/97-last-puppet-run'
fi

function wttr() {
    curl https://wttr.in/"${1:-}"
}

# for use on curl commandlines
# usage: curl -v --otherflags $(RESOLVE URL hostname)
# example: curl -v $(RESOLVE https://en.wikipedia.org/wiki/Special:BlankPage text-lb.eqsin.wikimedia.org)
function RESOLVE() {
    local URL="$1"
    local HOST="$2"
    echo '--resolve' $(python3 -c 'import socket;import sys; import urllib.parse as up;u=up.urlparse(sys.argv[1]);print(u.netloc+((":"+("443" if u.scheme == "https" else "80") if u.port is None else "")))' "$URL"):$(dig +short "$HOST") "$URL"
}

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
