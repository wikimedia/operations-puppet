HISTCONTROL="ignoreboth"
shopt -s autocd

GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUPSTREAM="auto verbose"
. /etc/bash_completion.d/git-prompt
PS1='\t \u@\h \w$(__git_ps1 " (%s)") \$ '

  function l {
    ls -CF $@
  }

  function ll {
    ls -l $@
  }

  function la {
    # Almost all - exclude . and ..:
    ls -A $@
  }

  function lal {
    ls -Al $@
  }

  function lah {
    ls -Alh $@
  }

alias g=git
alias v=vim
