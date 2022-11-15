case "$TERM" in
	xterm-256color)
		GIT_PS1_SHOWUNTRACKEDFILES=1
		GIT_PS1_SHOWDIRTYSTATE=1
		GIT_PS1_SHOWUPSTREAM="auto verbose"
		. /etc/bash_completion.d/git-prompt

		# copied from modules/profile/templates/kubernetes/kube-env.sh.erb
		# so it's always defined, modified to add a space in front
		__taavi_kube_env_ps1() {
			if [ -z "$K8S_CLUSTER" ] || [ -z "$TILLER_NAMESPACE" ]; then
				return
			fi

			echo " <${TILLER_NAMESPACE}/${K8S_CLUSTER}>"
		}

		TITLEBAR='\[\e]0;\u@\h \w\007\]'
		PROMPT='\[\033[00;33m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)")$(__taavi_kube_env_ps1) \$ '
		PS1="$TITLEBAR$PROMPT"
		;;
	*)
		;;
esac

alias ls="ls --color"
alias grep="grep --color"

alias g="git"
. /usr/share/bash-completion/completions/git
__git_complete g __git_main

alias os="sudo wmcs-openstack"

if [ -f /usr/bin/kubectl ]; then
	alias k="kubectl"

	source <(kubectl completion bash)
	complete -F __start_kubectl k
fi
