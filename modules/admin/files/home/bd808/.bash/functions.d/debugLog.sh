##
# Shell script debugging functions
#
#  author: Bryan Davis <bd808@bd808.com>
##

##
# Log a debug message.
#
# Writes timestamp, process id, caller script and line number and any
# arguments to stderr iff DL_DEBUG_ENABLE environment var is set to a non-empty
# string.
#
# @param $* Message to log
##
debugLog () {
  if [ -n "${DL_DEBUG_ENABLE}" ]; then
    {
      date +%Y-%m-%dT%H:%M:%S%z
      echo " [$$] "
      caller | awk '{printf "%s(%d)\n", $2, $1}'
      echo " - $*"
    } | paste -d '' -s -
  fi
}

dbgEnable () {
  export DL_DEBUG_ENABLE=1
}

dbgDisable () {
  export DL_DEBUG_ENABLE=
}

##
# Toggle debug status
##
dbg () {
  if [ -n "${DL_DEBUG_ENABLE}" ]; then
    dbgDisable
    echo "Shell debugging disabled."
  else
    dbgEnable
    echo "Shell debugging enabled."
  fi
}

# vim: se sw=2 ts=2 tw=78 et ft=sh:
