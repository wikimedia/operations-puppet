# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -l'
alias sudo='sudo '
alias treel='tree -L 2 --filesfirst -F'
alias diff='diff -u --color'
alias bat='batcat'
alias cp='cp --interactive'
alias tailf='tail -f'
alias gldoc='git log --decorate --oneline --color'
alias gll='git log --pretty=format:"%C(yellow)%h %Creset%s%Cblue [%ae] (%ad)" --decorate --numstat --date=relative --shortstat'
alias grpo='git remote prune origin'
alias gcd='cd $(git rev-parse --show-toplevel 2>/dev/null || echo .)'
alias ghd='git diff origin/HEAD..HEAD'
alias gcas='git commit --all --signoff'
alias k='kubectl'
alias kg='kubectl get'

# recursive sed
sedrec() {
    pattern=${1:?"${FUNCNAME[0]}: missing pattern: s/foo/bar/g"}
    shift
    dir="${1:-.}"

    find ${dir} -type f -exec sed -i "${pattern}" {} +
}

. .liquidprompt/liquidprompt

# update the shell history after each command, to share the shell history inside/outside screen sessions
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"
