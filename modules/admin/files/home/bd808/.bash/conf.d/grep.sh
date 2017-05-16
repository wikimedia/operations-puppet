#!/usr/bin/env bash

if $(grep --help 2>/dev/null | grep -q -- --color) ; then
  #colorize grep matches with a nice yellow
  # the LANG=C makes grep deal with multibyte chars better
  alias grep='GREP_COLOR="1;33;40" LANG=C grep --color=auto'
  alias fgrep='GREP_COLOR="1;33;40" LANG=C fgrep --color=auto'

else
  # the LANG=C makes grep deal with multibyte chars better
  alias grep='LANG=C grep'
  alias fgrep='LANG=C fgrep'
fi

