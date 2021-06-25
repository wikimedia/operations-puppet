#!/bin/bash
set -e
CONFD_FILE='/etc/conftool-state/mediawiki.yaml'
# First check if the confd file is stale or not. If it is, just exit
/usr/local/lib/nagios/plugins/check_confd_template "$CONFD_FILE" > /dev/null
master_dc=$(awk '/primary_dc/ { print $2 }' "$CONFD_FILE")
my_dc=$(cat /etc/wikimedia-cluster)
if [[ "$master_dc" = "$my_dc" ]];
then
    exec "$@"
else
    # We don't exit with an error status code, it doesn't really
    # make sense as this is an expected behaviour.
    echo "Skipping execution, not the master datacenter!"
fi
