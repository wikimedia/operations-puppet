# interactive shell specific config

# vim! if we can, vi if we can't
EDITOR=vi
hash vim &>/dev/null && EDITOR=vim
VISUAL=${EDITOR}
export EDITOR VISUAL

# append to history instead of replacing
shopt -s histappend >/dev/null 2>&1
# line oriented history
shopt -s lithist >/dev/null 2>&1
# allow correction of invalid commands
shopt -s histreedit >/dev/null 2>&1
# fancy globs
shopt -s extglob >/dev/null 2>&1
# I can't spell or type
shopt -s cdspell >/dev/null 2>&1
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize >/dev/null 2>&1
# don't tab complete on an empty line
shopt -s no_empty_cmd_completion >/dev/null 2>&1

# de-dup history; start cmd with a space to hide it
export HISTCONTROL=ignoredups:ignorespace
# ignore: repeats, dir lists, job control, quitters
export HISTIGNORE="&:l[sl]:[bf]g:exit"
# don't tab complete output files and other junk
export FIGNORE='*.o:*.pyc:*.class:.swp:.swa'

# find out right away when background jobs end
set -o notify

# configure fancy shell completion
[[ -f ${BASH_CONF}/bash_completion ]] && {
  # completion vars may be readonly, so check before spewing a bunch of errors
  $(readonly -p|grep BASH_COMPLETION >/dev/null 2>&1) || {
    export BASH_COMPLETION=${BASH_CONF}/bash_completion
    export BASH_COMPLETION_DIR=${BASH_CONF}/bash_completion.d
    . ${BASH_COMPLETION}
  }

  # more custom completions
  complete -C complete-ant-cmd ant
  complete -C complete-phing-cmd phing
}

# prompt tweaks
SHORT_HOST=${SHORT_HOST:-$(hostname -f|rev|cut -d. -f3-|rev)}
SHORT_HOST=${SHORT_HOST:-$(hostname -f)}
SHORT_HOST=${SHORT_HOST/.local/}
export SHORT_HOST

# git repo info (from git completion script)
GIT_PS1_SHOWDIRTYSTATE=yes
GIT_PS1_SHOWSTASHSTATE=yes
#GIT_PS1_SHOWUNTRACKEDFILES=yes
#GIT_PS1_SHOWUPSTREAM=auto
GIT_PS1_FORMAT=" (git %s)"
typeset -F | grep __gitdir &>/dev/null || function __gitdir { ''; }
typeset -F | grep __git_ps1 &>/dev/null || function __git_ps1 { ''; }

__vcs_ps1 () {
  __gitdir &>/dev/null && __git_ps1 "${GIT_PS1_FORMAT}"
}

# primary prompt on two lines:
# truncated hostname:/current/path (vcs status)
# username$
export PS1="${SHORT_HOST}:\w \[\033[1;30m\]\$(__vcs_ps1)\[\033[0m\]\n\u\$ "
# continuation prompt as empty spaces for easy copy-n-paste
export PS2="    "
# set -x prefix shows source file and line number
export PS4='$0:$LINENO+ '

# term title
[[ -n "${DISPLAY}" || "${TERM}" != "${TERM/xterm/}" ]] && {
  # set xterm title on prompt display
  typeset -F | grep set_term_title &>/dev/null &&
  set_term_title
}

# screen title
[[ $TERM =~ ^screen(-.*)?$ ]] && {
  # add a pretty screen buffer title
  $(typeset -F | grep set_screen_title >/dev/null 2>&1) && {
    set_screen_title "${USER}@${SHORT_HOST}"
  }
}

# turn off idle timeout if it's not readonly
$(readonly -p|grep TMOUT >/dev/null 2>&1) || export TMOUT=0

# vim:set sw=2 ts=2 et ft=sh:
