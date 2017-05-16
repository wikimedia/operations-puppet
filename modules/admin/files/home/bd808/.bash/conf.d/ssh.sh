# ssh hotness

alias ssh-rmkey="ssh-keygen -R"

# make ssh_auth_sock consistent for screen/tmux
STICKY_SOCK="$HOME/.ssh/sockets/ssh_auth_sock"
[[ -n "${SSH_AUTH_SOCK}" && "${SSH_AUTH_SOCK}" != "${STICKY_SOCK}" ]] && {
  unlink "${STICKY_SOCK}" 2>/dev/null
  ln -s "${SSH_AUTH_SOCK}" "${STICKY_SOCK}"
  export SSH_AUTH_SOCK="${STICKY_SOCK}"
}
unset STICKY_SOCK

# vim: se sw=2 ts=2 sts=2 et ft=sh :
