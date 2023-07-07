#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail
# This script should be run as root. Auto-sudo in case it wasn't done on the command line.
if [[ "$EUID" != 0 ]]; then
    echo "Becoming root..."
    exec sudo "$0" "$@"
fi

function help() {
cat <<EOF
mw-debug-repl - launch a MediaWiki REPL in the kubernetes mw-debug environment.

Usage: mw-debug-repl [-e] [-d <datacenter>] [-w <wiki-name>|<wiki-name>]

OPTIONS:
  -e                 Launch eval.php, instead of the default shell.php as REPL
  -d|--datacenter    Pick a specific datacenter (by default the master will be picked)
  -w|--wiki          Pick a wiki. For compatibility reasons, the flag can be omitted.
  -h|--help          Show this help message

EXAMPLES:

Launch an eval.php shell for itwiki in eqiad

  $ sudo $0 -e -d eqiad --wiki itwiki
  # Also valid:
  $ sudo $0 -e --datacenter eqiad itwiki

Launch shell.php for enwiki

  $ sudo $0 enwiki
  $ sudo $0 --wiki enwiki

EOF
}

### Main script

REPL="shell.php"
WIKI=""
DC=""

OPTS=$(getopt -o hew:d: -l help,wiki:,datacenter: -- "$@")
eval set -- "$OPTS"
while true; do
    case "$1" in
        -h | --help ) # display Help
            help
            exit;;
        -e ) # use eval.php instead of shell.php
            REPL="eval.php"; shift;;
        -w | --wiki )
            WIKI="$2"; shift 2;;
        -d | --datacenter )
            DC="$2"; shift 2;;
        -- )
            shift; break;;
        *)
            echo "Error: invalid option '$1'. Please run $0 -h for help"\
            exit 1;;
    esac
done
if [[ "$WIKI" == "" ]]; then
    if [ -z "$1" ]; then
        echo "Error: a wiki should be provided on the command line"
        echo
        help
        exit 1
    fi
    WIKI=$1
    shift
fi

if [[ "$DC" == "" ]]; then
    DC=$(confctl --object-type mwconfig select 'name=WMFMasterDatacenter' get | jq .WMFMasterDatacenter.val | sed s/\"//g)
fi
echo "Finding a mw-debug pod in $DC..."
export KUBECONFIG="/etc/kubernetes/admin-$DC.config"
PODNAME=$(kubectl -n mw-debug get pods --field-selector=status.phase=Running -o name | head -n 1)
if [ -z "$PODNAME" ]; then
    echo "Could not find a running pod. Check if the datacenter you picked is running mw-debug at the moment"
    exit 1
fi
echo "Now running $REPL for $WIKI inside ${PODNAME}..."
kubectl -n mw-debug exec "$PODNAME" -c mediawiki-pinkunicorn-app -ti -- php /srv/mediawiki/multiversion/MWScript.php "$REPL" --wiki "$WIKI"
