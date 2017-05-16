# Set xterm title
# If no string given, default to "user@host (tty)"
# arg *: title string
set_term_title () {
  local tt="${USER}@${SHORT_HOST:-${HOSTNAME%%.*}} ($(tty|tr / ' '|awk '{print $NF}'))"
  [ -n "$*" ] && tt="$*"
  echo -ne "\033]0;${tt}\007"
}

# Set screen buffer title
# If no string given, default to "user@host"
# arg *: title string
set_screen_title () {
  local st="${USER}@${SHORT_HOST:-${HOSTNAME%%.*}}"
  [ -n "$*" ] && st="$*"
  echo -ne "\033k${st}\033\\"
}

# Alias for ssh that resets term title and screen title on exit
# arg *: arguments to pass to ssh
ssh () {
  $(which ssh) "$@"

  # reset term and screen titles if ssh wasn't a batch mode call
  [[ "$*" != *Batchmode* ]] && {
    set_term_title
    set_screen_title
  }
}

# Alias for su that resets term title and screen title on exit
# arg *: arguments to pass to su
su () {
  # work around tcsh bug with LS_COLORS
  # see http://cygwin.com/ml/cygwin/2006-01/msg00767.html
  OLD_LS_COLORS=${LS_COLORS}
  LS_COLORS=
  export LS_COLORS

  $(which su) "$@"

  LS_COLORS=${OLD_LS_COLORS}
  set_term_title
  set_screen_title
}

# vim:sw=2 ts=2 sts=2 et ft=sh:
