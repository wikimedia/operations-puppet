test -r ~/.bashrc && . ~/.bashrc
alias k=kubectl
complete -o default -F __start_kubectl k
# make it harder for me to do stuff in the wrong DC
kube_env_short() {
  local f="${KUBECONFIG##*/}"
  f="${f%.config}"
  echo "${f##*-}"
}
export PS1='[\u@\h$( [[ -n $KUBECONFIG ]] && echo " $(kube_env_short)" )] \w\$ '
