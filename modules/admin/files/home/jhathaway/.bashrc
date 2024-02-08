#!/bin/bash

set -o pipefail
shopt -s lastpipe

# macOS hacks, ventura hack for tmux-256color, may be removed when on sonoma
if [[ "$(uname)" == 'Darwin' ]]; then
	export TERMINFO_DIRS=$TERMINFO_DIRS:~/.local/share/terminfo
fi

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

# Typing is hard, ⌨️
function grpe { grep "$@"; }

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

if [[ "$(uname)" == 'Darwin' ]]; then
	# brew install git
	git_ps1=/usr/local/etc/bash_completion.d/git-prompt.sh
else
	git_ps1=/usr/lib/git-core/git-sh-prompt
fi
# shellcheck source=/usr/lib/git-core/git-sh-prompt
if [[ -e "$git_ps1" ]]; then
	source "$git_ps1"
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

# Poor man's version of rpl, http://www.laffeycomputer.com/rpl.html
function rpl {
	regexp=$1
	replacement=$2
	# exclude hidden dirs
	grep -E -r -l -Z --exclude-dir='.?*' "$regexp" |
		while IFS='' read -r -d $'\0' file; do
			if ! [[ -f "$file" && -r "$file" ]]; then
				continue
			fi
			printf '%s\n' "$file"
			sed --in-place -Ee "s/${regexp}/${replacement}/g" "$file"
		done
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
function ring {
	tput bel
}

# Print last command
function lc {
	fc -n -l -1 "$@" | sed -E 's/^[[:space:]]*//'
}

# TODO add open & closed phab tasks?
function wmf-past-work {
	local usage
	local until
	local since
	local OPTIND
	local OPTARG

	usage=$(
		cat <<-'EOF'
			Usage:
			  -s since, e.g. 2023-04-01
			  -u until, e.g. 2023-06-30
		EOF
	)

	while getopts ":hs:u:" opt; do
		case "${opt}" in
		s)
			since=$OPTARG
			;;
		u)
			until=$OPTARG
			;;
		h)
			printf '%s\n' "$usage"
			return 0
			;;
		\?)
			printf '%s\n' "$usage" 1>&2
			return 1
			;;
		esac
	done
	shift $((OPTIND - 1))

	if ! [[ -v 'since' ]] || ! [[ -v 'until' ]]; then
		printf '%s\n' "$usage" 1>&2
		return 1
	fi

	printf '\n## Completed Tasks\n\n'
	task context work >/dev/null
	task "end.after:$since" and "end.before:$until" completed 2>/dev/null

	printf '\n## Git Commits\n'
	declare -A wmf_repos=(
		['puppet']='production'
		['production-images']='master'
		['deployment-charts']='master'
		['docker-pkg']='master'
		['dcl']='main'
	)
	for repo in "${!wmf_repos[@]}"; do
		PAGER='' git -C ~/src/wmf/"$repo" fetch 2>/dev/null
		# Format: Wed Jul 26 16:39  adadce2  typo
		# --since=1.weeks \
		local log_args=(
			'--pretty=format:%<(18,trunc)%ch%<(12,trunc)%h%s'
			'--reverse'
			"--since=$since"
			"--until=$until"
			'--author=jhathaway@wikimedia.org'
			'--author=jesse@mbuki-mvuki.org'
		)
		mapfile -t commits < <(PAGER='' git -C ~/src/wmf/"$repo" log "${log_args[@]}" origin/"${wmf_repos["$repo"]}")
		if (("${#commits[@]}" > 0)); then
			printf '\n### %s repository\n\n' "$repo"
			printf -- '- %s\n' "${commits[@]}"
		fi
	done
}

function wmf-last-week {
	# end.after:2015-05-0 and end.before:2015-05-31
	printf '## Etherpad\n'
	printf -- '- <https://etherpad.wikimedia.org/p/SRE-Foundations-%s>\n' "$(date -I -d 'last monday + 7 days')"
	wmf-past-work -s "$(date -I -d 'last sunday - 7 days')" -u "$(date -I -d 'last saturday')"
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

function gdoc-img-copy {
	curl "$(
		xclip -selection clipboard -o -t text/html |
			xmllint --html -xpath "string(//img/@src)" -
	)" -o - |
		xclip -selection clipboard -target image/png
}

# Disposable Debian container
function bubble-up {
	# TODO pull down dotfiles, but don't mount home?, re-use sync-dotfiles
	# TODO default image
	if [[ $# -gt 0 ]]; then
		args=("$@")
	else
		args=('debian:stable')
	fi
	podman run --rm -it -w /root --entrypoint bash "${args[@]}"
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
function md2phab {
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

# Sync my most used dotfiles, somewhere?
# e.g.
#   sync-dotfiles ~/src/wmf/puppet/modules/admin/files/home/jhathaway/
#   sync-dotfiles butter.com:
#   sync-dotfiles -e "ssh -p 22220" localhost:
# NOTE: rsync must be present on the remote side
sync-dotfiles() {
	rsync --exclude '.git' -a \
		~/.profile \
		~/.bash-rsi \
		~/.inputrc \
		~/.bashrc \
		~/.tmux.conf \
		"$@"
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
## Save multiline commands verbatim to the history file
shopt -s cmdhist
shopt -s lithist
## Don't put duplicate lines in the history. See bash(1) for more options
HISTCONTROL=erasedups:ignorespace:ignoredups
HISTIGNORE="&:ls:[bf]g:exit"
HISTFILESIZE=400000000
HISTSIZE=10000
## Append to history file
shopt -s histappend

PROMPT_COMMAND+=('history -a')
PROMPT_COMMAND+=('git-root')
## Disable XON/XOFF, so we can use Ctrl-s to search forwards
stty -ixon

# Exports
export LESS='--LONG-PROMPT --ignore-case --tabs=4 --RAW-CONTROL-CHARS --mouse --quit-if-one-screen'
export EDITOR=vi
# Ensure we get hyphen-minus in man pages, don't use en_US.UTF-8, or manpages
# will use a hyphen, https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1041731
export LANG=en_US.UTF-8
# export LANG=en_US
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
# ssh tab completion from avahi
export COMP_KNOWN_HOSTS_WITH_AVAHI=1
# fix jq colors, https://github.com/jqlang/jq/issues/2924
export JQ_COLORS='1;30:0;39:0;39:0;39:0;32:1;39:1;39'

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

# Bash completion
if [[ "$(uname)" == 'Darwin' ]]; then
	# stolen from https://docs.brew.sh/Shell-Completion
	if type brew &>/dev/null; then
		HOMEBREW_PREFIX="$(brew --prefix)"
		if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then
			# shellcheck disable=SC1090,SC1091
			source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
		else
			for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
				# shellcheck disable=SC1090
				[[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
			done
		fi
	fi
else
	if ! shopt -oq posix; then
		if [ -f /usr/share/bash-completion/bash_completion ]; then
			. /usr/share/bash-completion/bash_completion
		elif [ -f /etc/bash_completion ]; then
			. /etc/bash_completion
		fi
	fi
fi

# Completion for the Kubernetes 🧅!
k8s_cmds=(kubectl minikube helm helmfile dcl)
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
if [[ "$(uname)" == 'Linux' ]]; then
	alias lsblk='lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINT,LABEL'
	alias o="xdg-open"
	alias ls='ls -T4 -w80 -p'
fi
alias v='view'
# ipcalc-ng has IPv6 support
alias ipcalc='ipcalc-ng'

# shellcheck disable=SC2016
PS1_DEMO='$(dollar $?) '
export PS1_DEMO

export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
PS1='\[\e[36m\e[3m\]\h$(wmf-site):\[\e[23m\][\[\e[m\]\w\[\e[36m\]]\[\e[m\]$(git_ps1 " (%s)")'
if [[ $(type -t puppet_env_ps1 2>/dev/null) == 'function' ]]; then
	PS1+=' $(puppet_env_ps1)'
fi
PS1+='\[\e[1;33m\]$(jobs_ps1)\[\e[m\]\n\[\e[36m\e[m\]$(dollar $?) '
