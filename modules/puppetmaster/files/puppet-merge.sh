#!/bin/bash

set -eu
RED=$(tput bold; tput setaf 1)
GREEN=$(tput bold; tput setaf 2)
CYAN=$(tput bold; tput setaf 6)
RESET=$(tput sgr0)
git_user=gitpuppet
USAGE=0
LABS_PRIVATE=0
# CA_SERVER, MASTERS and WORKERS are configured in /etc/puppet-merge.conf
CA_SERVER=''
MASTERS=''
WORKERS=''
. /etc/puppet-merge.conf

if [ -z "$CA_SERVER" ] || [ -z "$MASTERS" ] || [ -z "$WORKERS" ]; then
  printf 'Error reading variables from /etc/puppet-merge.conf\\n' >&2
  exit 1
fi

if [ "$(hostname -f)" != "${CA_SERVER}" ];then
  printf "To ensure consistent locking please run puppet-merge from: %s\\n" ${CA_SERVER} >&2
  exit 1
fi

if [ "$(whoami)" = "gitpuppet" ]
then
  printf "This script should only be run as a real users.  gitpuppet should use /usr/local/bin/puppet-merge.py\\n" >&2
  exit 1
fi

lock() {
  LABS_PRIVATE=$1
  if [ "${LABS_PRIVATE}" -eq 1 ]
  then
    LOCKFILE=/var/lock/puppet-merge-labs-lock
  else
    LOCKFILE=/var/lock/puppet-merge-prod-lock
  fi
  LOCKFD=9
  eval "exec ${LOCKFD}>\"$LOCKFILE\""
  trap 'rm -f $LOCKFILE' EXIT
  if ! flock -xn $LOCKFD
  then
      trap EXIT
      # Close our own fd to the lockfile before checking ownership below.
      eval "exec ${LOCKFD}>&-"
      # Any subprocess of the script that holds the lock will also have an open
      # filehandle to $LOCKFILE.  Grab just one such PID for pstree (doesn't
      # matter which).
      # shellcheck disable=SC2046
      PSTREE=$(pstree -su $(fuser "$LOCKFILE" 2>/dev/null | awk '{print $1}'))
      # If given an empty command line, or a nonexistent PID, pstree -su will
      # output all processes on the system, which isn't helpful.  Normal usage
      # of this script should only ever yield a single line of pstree output.
      if [ "$(wc -l <<<"$PSTREE")" -eq 1 ]
      then
        PSTREE="locking process tree: $PSTREE"
      else
        PSTREE="could not determine lock holder"
      fi
      printf "E: failed to lock, another puppet-merge running on this host?\\n%s\\n" "${PSTREE}" >&2
      exit 1
  fi
}
check_remote_error() {
  exit_code=$1
  worker=$2
  repo=$3
  if [ "${exit_code}" -eq 0 ]; then
    printf "%sOK%s: puppet-merge on %s (%s) succeeded\\n" "$GREEN" "$RESET" "$worker" "$repo"
  elif [ "${exit_code}" -eq 99 ]; then
    printf "%sNO CHANGE%s: puppet-merge on %s (%s) no change\\n" "${CYAN}" "$RESET" "$worker" "$repo"
  else
    printf "%sERROR%s: puppet-merge on %s (%s) failed\\n" "${RED}" "$RESET" "$worker" "$repo"
  fi
}

merge() {
  servers=$1
  repo=$2
  sha=$3
  git_user=$4
  for server in ${servers}; do
    echo "${CYAN}===> Starting run${RESET} on ${server}..."
    su - "$git_user" -c "ssh -t -t ${server} true --${repo} ${sha} 2>&1"
    check_remote_error "$?" "${server}" "${repo}"
    echo
  done
}

usage="$(basename "${0}") [-y|--yes] [-p|--labsprivate] [-q|--quiet] [-d|--diffs] [SHA1]

Fetches changes from origin and from all submodules.
Shows diffs between HEAD and SHA1 (default FETCH_HEAD)
and prompts for confirmation.

If the changes are acceptable, HEAD will be fast-forwarded
to SHA1.

It also runs conftool-merge if necessary.

SHA1 equals FETCH_HEAD if not specified.

If no SHA1 is specified, and --labsprivate is not specified,
runs on both the ops and labsprivate repos.

-y / --yes: skip prompting for confirmation
-p / --labsprivate: merge only the labsprivate repo
-d / --diffs: only show diffs, don't perform any merges
-q / --quiet: don't output diffs
"
# preserve arguments before we shift them all
# Our original arguments get passed on, unchanged, to puppet-merge.py.
ORIG_ARGS=( "$@" )
TEMP=$(getopt -o yhqd --long yes,help,quiet,labsprivate,diffs -n "$0" -- "$@")
# shellcheck disable=SC2181
if [ "$?" != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"
while true; do
    case "$1" in
        -h|--help) USAGE=1; shift ;;
        -p|--labsprivate) LABS_PRIVATE=1; shift ;;
        --) shift ; break ;;
        *) echo 'Internal error!' >&2; exit 1 ;;
    esac
done

if [ $USAGE -eq 1 ]; then
    echo "$usage" && exit 0;
fi

lock $LABS_PRIVATE

# if a specific sha1 was not requested push FETCH_HEAD on to the list of arguments
if [ $# -gt 1 ]
then
  echo "Error: Too many arguments"
  echo $usage
  exit 1
elif [ $# -eq 1 ]
then
  FETCH_SHA1=1
else
  FETCH_SHA1=0
  ORIG_ARGS=( "$@" "FETCH_HEAD")
fi

# From this point continue despite errors on remote masters. After a change
# has been merged on the local master a remote merge failure should not
# cause all remaining masters to be aborted and left out of sync.
set +e

if [ $LABS_PRIVATE -eq 1 ]; then
    # if --labsprivate is used just sync the labsprivate repo
    /usr/local/bin/puppet-merge.py "${ORIG_ARGS[@]}"
    LABS_EXIT=$?
else
    # We want to do a labs merge every time we do an ops merge -- except if
    # the user gave us an explicit sha1, which only makes sense for one repo.
    if [ $FETCH_SHA1 -eq 0 ]; then
      /usr/local/bin/puppet-merge.py --labsprivate "${ORIG_ARGS[@]}"
      LABS_EXIT=$?
    fi
    /usr/local/bin/puppet-merge.py --ops "${ORIG_ARGS[@]}"
    PROD_EXIT=$?
fi
# puppet-merge.py exits with 99 if no merge was performed
if [ ${PROD_EXIT} -eq 99 ] && [ ${LABS_EXIT} -eq 99 ]; then
  printf '%sNo changes to merge%s\n' "${GREEN}" "${RESET}"
  exit 0
elif [ ${PROD_EXIT} -eq 99 ]; then
  printf '%sNo Production changes to merge%s\n' "${GREEN}" "${RESET}"
elif [ ${LABS_EXIT} -eq 99 ]; then
  printf '%sNo LABS changes to merge%s\n' "${GREEN}" "${RESET}"
elif [ ${PROD_EXIT} -ne 0 ]; then
  printf '%sProblems merging production%s\n' "${RED}" "${RESET}"
elif [ ${LABS_EXIT} -ne 0 ]; then
  printf '%sProblems merging LABS%s\n' "${RED}" "${RESET}"
fi

# Grab the SHAs that were exported by the Python script, so that
# on the remote hosts, we merge exactly the set of changes we prompted
# the local user to confirm merging.
LABSPRIVATE_SHA=$(cat /srv/config-master/labsprivate-sha1.txt)
OPS_SHA=$(cat /srv/config-master/puppet-sha1.txt)

# Note: The "true" command is passed on purpose to show that the command passed
# to the SSH sessions is irrelevant. It's the SSH forced command trick on the
# worker end that does the actual work. Note that args (the SHA1 and
# --labsprivate/--ops switch) are used.

if [ $LABS_PRIVATE -eq 1 ] && [ ${LABS_EXIT} -eq 0 ]; then
  merge "${MASTERS}" 'labsprivate' "${LABSPRIVATE_SHA}" "${git_user}"
elif [ $LABS_PRIVATE -eq 0 ]; then
  if [ ${LABS_EXIT} -eq 0 ]; then
    merge "${MASTERS}" 'labsprivate' "${LABSPRIVATE_SHA}" "${git_user}"
  fi
  if [ ${PROD_EXIT} -eq 0 ]; then
    merge "${WORKERS}" 'ops' "${OPS_SHA}" "${git_user}"
  fi
fi

# Only run this once, and only if we're merging the prod repo
if [ $LABS_PRIVATE -eq 0 ]; then
    echo "Now running conftool-merge to sync any changes to conftool data"
    /usr/local/bin/conftool-merge
fi
# vim: set syntax=sh:
