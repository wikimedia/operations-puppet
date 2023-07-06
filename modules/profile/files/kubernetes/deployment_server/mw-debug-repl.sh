#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail

function help() {
cat <<EOF
mw-debug-repl - launch a MediaWiki REPL in the kubernetes mw-debug environment.

Usage: mw-debug-repl [-e] [-d <datacenter>] [-w <wiki-name>]

OPTIONS:
  -e    Launch eval.php, instead of the default shell.php as REPL
  -d    Pick a specific datacenter (by default the master will be picked)
  -w    Pick a wiki. Defaults to "aawiki".
EOF
}

### Main script

REPL="shell.php"
WIKI="aawiki"
DC=""
# Allow overriding of PHP version or flags
[ "$PHP" = "" ] && PHP=php

while getopts ":hew:d:" option; do
    case $option in
        h) # display Help
            help
            exit;;
        e) # use eval.php instead of shell.php
            REPL="eval.php";;
        w)
            WIKI="$OPTARG";;
        d)
            DC="$OPTARG";;
        *)
            echo "Error: invalid option '$option'. Please run $0 -h for help"\
            exit 1;;
    esac
done

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
kubectl -n mw-debug exec "$PODNAME" -c mediawiki-pinkunicorn-app -ti -- "$PHP" /srv/mediawiki/multiversion/MWScript.php "$REPL" --wiki "$WIKI"