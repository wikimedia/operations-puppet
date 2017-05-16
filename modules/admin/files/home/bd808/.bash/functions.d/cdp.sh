# Change to a project root directory.
#
# Use by sourcing into your shell
#
# Adapted from a script that Joey wrote.
#
#  author: Bryan Davis <bd808@bd808.com>
# requires: debugLog

function cdp () {
  local PROJECTS_ROOT SUBS SUBST CURRENT TARGET TRUNC GUESS
  # Directory that projects are found in
  PROJECTS_ROOT=${CDP_ROOT:-${HOME}/projects}
  debugLog "PROJECTS_ROOT=${PROJECTS_ROOT}"

  # Subdirectories that projects may be divided into
  SUBS=
  SUBST=$(find ${PROJECTS_ROOT} -maxdepth 1 -mindepth 1 -type d -print)
  for d in ${SUBST}; do
    # remove PROJECT_ROOT/ prefix from dir names
    SUBS="${SUBS}${SUBS:+ }${d#${PROJECTS_ROOT}/}"
  done
  debugLog "SUBS=${SUBS}"

  # Project current directory is associated with
  CURRENT=${PWD#${PROJECTS_ROOT}/}
  debugLog "CURRENT=${CURRENT}"

  # Project to change dir to
  TARGET=${1:-${CURRENT}}
  debugLog "TARGET=${TARGET}"

  # adjust for lanaguage based project root subdirs
  for r in ${SUBS} ; do
    TRUNC=${TARGET#${r}/};
    if [ "${TARGET}" != "${TRUNC}" ]; then
      debugLog "Shifting ${r}";
      PROJECTS_ROOT=${PROJECTS_ROOT}/${r}
      debugLog "PROJECTS_ROOT=${PROJECTS_ROOT}"
      TARGET=${TRUNC}
      debugLog "TARGET=${TARGET}"
    fi
  done

  # if being used without an argument, truncate to project base dir
  if [ -z "$1" ]; then
    TARGET=${TARGET%%/*}
  fi

  # try to find the directory to cd to
  for r in . ${SUBS} ; do
    GUESS="${PROJECTS_ROOT}/${r}/${TARGET}"
    debugLog "GUESS=${GUESS}"
    if [ -d ${GUESS} ]; then
      debugLog cd "${GUESS}"
      cd "${GUESS}"
      return $?
    fi
  done

  # cd failed
  echo "Can't find target dir : ${1:-${CURRENT}}" >&2
  return 1
} #end cdp

# custom tab completion for cdp
function _cdp () {
  local TARGET CUR DIRS OPTS
  TARGET=${CDP_ROOT:-${HOME}/projects}
  COMPREPLY=()
  CUR="${COMP_WORDS[COMP_CWORD]}"
  DIRS=$(cd $TARGET; compgen -o dirnames $2)
  OPTS=$(for i in $DIRS; do if [[ $i != ".git" ]]; then echo $i/; fi; done)
  if [[ ${CUR} == * ]] ; then
    COMPREPLY=( $(compgen -W "${OPTS}" -- ${CUR}) )
    return 0
  fi
} #end _cdp
complete -o nospace -F _cdp cdp

# vim: se sw=2 ts=2 tw=78 et ft=sh:
