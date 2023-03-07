#!/bin/bash

set -o pipefail
shopt -s lastpipe

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Get our secrets, 🤐
if [[ -f ~/.env_secrets ]]; then
	# shellcheck source=.env_secrets
	source ~/.env_secrets
fi

# shellcheck source=.bash-rsi/bashrc
source ~/.bash-rsi/bashrc

pathmunge() {
	if ! echo "${PATH}" | grep -Eq "(^|:)$1($|:)"; then
		if [ "$2" = "after" ]; then
			PATH=$PATH:$1
		else
			PATH=$1:$PATH
		fi
	fi
}

# https://unix.stackexchange.com/questions/18087/can-i-get-individual-man-pages-for-the-bash-builtin-commands
man() {
	local cur_width

	cur_width=$(tput cols)

	if [[ $cur_width -gt $MANWIDTH ]]; then
		cur_width=$MANWIDTH
	fi

	if [[ "${#@}" -gt 1 ]]; then
		MANWIDTH="${cur_width}" command -p man "$@"
	else
		case "$(type -t "$1"):$1" in
		builtin:*)
			help "$1" | "${PAGER:-less}" # built-in
			;;
		*[[?*]*)
			help "$1" | "${PAGER:-less}" # pattern
			;;
		*)
			MANWIDTH="${cur_width}" command -p man "$@" # something else, presumed to be an external command
			;;
		esac
	fi
}

fe() {
	local files
	mapfile -t files <(fzf-tmux --query="$1" --multi --select-1 --exit-0)
	if [[ "${#files[@]}" -gt 0 ]]; then
		${EDITOR:-vim} "${files[@]}"
	fi
}

# Stolen from /usr/share/doc/fzf/examples/key-bindings.bash
__fzfcmd() {
	[[ -n "${TMUX_PANE-}" ]] && { [[ "${FZF_TMUX:-0}" != 0 ]] || [[ -n "${FZF_TMUX_OPTS-}" ]]; } &&
		echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

__fzf_select__() {
	local cmd opts
	cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
	opts="--height ${FZF_TMUX_HEIGHT:-40%} --bind=ctrl-z:ignore --reverse ${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-} -m"
	eval "$cmd" |
		FZF_DEFAULT_OPTS="$opts" $(__fzfcmd) "$@" |
		while read -r item; do
			printf '%q ' "$item" # escape special chars
		done
}

fzf-file-widget() {
	local selected
	selected="$(__fzf_select__ "$@")"
	READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
	READLINE_POINT=$((READLINE_POINT + ${#selected}))
}

bind -m vi-command -x '"\C-t": fzf-file-widget'
bind -m vi-insert -x '"\C-t": fzf-file-widget'

dollar() {
	local rc
	local out

	rc=$1
	if [[ $rc -eq 0 ]]; then
		printf -v out '\[\e[36m\]\$\[\e[m\]'
	else
		printf -v out '\[\e[1;31m\]\$\[\e[m\]'
	fi
	printf '%s' "${out@P}"
}

corp() {
	ssh -D 8123 -f -C -q -N support01.chi
}

function join_by {
	local d=${1-} f=${2-}
	if shift 2; then
		printf %s "$f" "${@/#/$d}"
	fi
}

# Display the current background jobs in a format suitable for your PS1
jobs_ps1() {
	local exit_status=$?
	declare -a job_cmds
	while read -r job_count _ cmd; do
		job_cmds+=("${job_count} ${cmd}")
	done < <(jobs)
	if ((${#job_cmds[@]} > 0)); then
		printf ' '
		join_by ', ' "${job_cmds[@]}"
	fi
	return $exit_status
}

# source __git_ps1
if [[ -e /usr/lib/git-core/git-sh-prompt ]]; then
	source /usr/lib/git-core/git-sh-prompt
fi

git_ps1() {
	# preserve exit status for other other PS1 functions
	local exit_status=$?
	# TODO: Create a better structure to conditionally enable prompt
	# components?
	if ! declare -F __git_ps1 >/dev/null; then
		return $exit_status
	fi
	# only display git prompt if current repo is not our dotfiles repo
	if [[ $(git rev-parse --absolute-git-dir 2>/dev/null) != ~/.git ]]; then
		__git_ps1 "${@}"
	fi
	return $exit_status
}

# Read html from a pipe and display it in chrome
function chromepipe() {
	shopt -s lastpipe
	base64 -w0 | read -r data
	chrome -p -- --new-window 'data:text/html;base64,'"${data}"
}

# Strip terminal escape sequences from stdin
function noescape {
	sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'
}

function oneliner() {
	sed -E -e 's/#.*$//' -e '/^\s*$/d' -e 's/$/;/' -e 's/\s+/ /g' -e 's/(then|else|\{);/\1/g' | paste -s -d' '
}

function ncdu() {
	NO_COLOR=true command ncdu "$@"
}

# World Clock
function wclock() {
	local fmt='%R %l:%M%p'
	TZ=America/Los_Angeles date \
		'+Los Angeles : '"$fmt"
	TZ=America/Chicago date \
		'+Chicago     : '"$fmt"
	TZ=America/New_York date \
		'+New York    : '"$fmt"
	TZ=Europe/Madrid date \
		'+Madrid      : '"$fmt"
	TZ=Europe/Berlin date \
		'+Berlin      : '"$fmt"
	TZ=Etc/UTC date \
		'+UTC         : '"$fmt"
}

# Beep the terminal when you read a line from input
function line-beeper {
	while IFS= read -r line; do
		printf '%s\a\n' "$line"
	done
}

# Beep the terminal
function beep {
	tput bel
}

# Print last command
function lc {
	fc -n -l -1 "$@"
}

function wmif-weekly-meeting {
	printf '## Etherpad\n'
	printf -- '- <https://etherpad.wikimedia.org/p/SRE-Foundations-%s>\n' "$(date -I)"
	printf '\n## Completed Tasks\n'
	task context work >/dev/null
	task end.after:today-1wk completed
	printf '\n## Git Commits\n'
	PAGER='' git -C ~/src/wmf/puppet fetch
	PAGER='' git -C ~/src/wmf/puppet log --oneline --since=1.weeks --author=jhathaway@wikimedia.org origin/production
}

# Create a gerrit link from a commit hash
# e.g. https://gerrit.wikimedia.org/r/plugins/gitiles/operations/puppet/+/feee1540547412d9bc4429df570a3c6da151162e
function wmf-gerrit-link {
	commit=$1
	origin_url=$(git remote get-url origin)
	gerrit_base='https://gerrit.wikimedia.org/r/'
	gitiles='https://gerrit.wikimedia.org/r/plugins/gitiles'
	repo_path=${origin_url#"$gerrit_base"}
	printf '%s/%s/+/%s\n' "$gitiles" "$repo_path" "$commit"
}

# Disposable debian container
function bubble-up {
	local distro=${1:-debian:latest}
	podman run --rm -it -v .:/root -w /root "$distro" bash
}

# Kubernetes functions
function k8s-rm-completed-pods {
	kubectl delete pod --field-selector=status.phase==Succeeded
}

# Git functions
function git-root {
	declare -g gr
	export gr
	gr="$(git rev-parse --show-toplevel 2>/dev/null)"
}

# Convert to phabricators remarkup language
function md-to-phab {
	cmd=(pandoc -t remarkup.lua -f markdown)
	if [[ -v '1' ]]; then
		cmd+=("$1")
	fi
	"${cmd[@]}"
}

# Display the Wikimedia datacenter name
wmf-site() {
	local exit_status=$?
	local wmc='/etc/wikimedia-cluster'
	if [[ -f "$wmc" ]]; then
		printf '(%s)' "$(<"$wmc")"
	fi
	return $exit_status
}

# sync my most used dotfiles, somewhere?
# e.g.
#   sync-dotfiles ~/src/wmf/puppet/modules/admin/files/home/jhathaway/
#   sync-dotfiles butter.com:
# NOTE: rsync must be present on the remote side
sync-dotfiles() {
	rsync --exclude '.git' -a \
		~/.profile \
		~/.bash-rsi \
		~/.inputrc \
		~/.bashrc \
		~/.tmux.conf \
		"$1"
}

# set umask
umask u=rwx,g=rwx,o=rx

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
# extended globbing, including negating
shopt -s extglob
shopt -s globstar
# List outstanding jobs rather than exiting
shopt -s checkjobs
# Ensure PROMPT_COMMAND is an array
PROMPT_COMMAND=()

# History
# Save multiline commands verbatim to the history file
shopt -s cmdhist
shopt -s lithist
HISTCONTROL=erasedups:ignorespace:ignoredups
HISTIGNORE="&:ls:[bf]g:exit"
HISTFILESIZE=400000000
HISTSIZE=10000
# Append to history file
PROMPT_COMMAND+=('history -a')
PROMPT_COMMAND+=('git-root')

# Exports
export LESS='--LONG-PROMPT --ignore-case --tabs=4 --RAW-CONTROL-CHARS --mouse --quit-if-one-screen'
export EDITOR=vi
export LIBVIRT_DEFAULT_URI='qemu:///system'
export RMADISON_ARCHITECTURE='amd64'
export DEBFULLNAME='Jesse Hathaway'
export DEBEMAIL='jesse@mbuki-mvuki.org'
export WATCH_INTERVAL=1 # 2secs just seems wierd!
# Makes manual pages more readable
export MANWIDTH=80
# Allows less to know the total line length via stdin, by going to the EOF,
# this then allows it to generate a percentage in the status line.
export MANPAGER='less +Gg'
# Don't put duplicate lines in the history. See bash(1) for more options

shopt -s histappend

# podman docker compat
export DOCKER_HOST="unix:///run/user/${UID}/podman/podman.sock"

# Java
JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')
export JAVA_HOME

# CDPATH for common directories
CDPATH=.:~:~/src:

# add sbin
pathmunge /sbin after
pathmunge /usr/sbin after
# personal scripts
pathmunge ~/bin after
pathmunge ~/.local/bin after
# haskell
pathmunge ~/.cabal/bin
# nodejs
pathmunge ~/node_modules/.bin after
# rust
pathmunge ~/.cargo/bin after
# puppet
pathmunge /opt/puppetlabs/bin after
# go
pathmunge ~/go/bin after

# Completion
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

# Completion for the Kubernetes 🧅!
k8s_cmds=(kubectl minikube helm helmfile)
for cmd in "${k8s_cmds[@]}"; do
	if command -v "$cmd" >/dev/null; then
		# shellcheck disable=SC1090
		source <($cmd completion bash)
	fi
done

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# set vi mode
set -o vi

# tabs at 4 columns
tabs -4

# Aliases
alias xclip="xclip -selection clipboard"
alias lsblk='lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINT,LABEL'
alias o="xdg-open"
alias ls='ls -T4 -w80 -p'
alias v='view'

export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
PS1='\[\e[36m\e[3m\]\h$(wmf-site):\[\e[23m\][\[\e[m\]\w\[\e[36m\]]\[\e[m\]$(git_ps1 " (%s)")\[\e[1;33m\]$(jobs_ps1)\[\e[m\]\n\[\e[36m\e[m\]$(dollar $?) '
