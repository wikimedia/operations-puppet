#/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

/usr/bin/logger -i -t ${0} "restart firewall components post ferm management"

# Ferm expects to handle all firewall state
# and that does not mesh well with dynamic chain management.
# We tell the k8s stack here to restart
#
# This should be no more invasive than a rescheduling
# of a POD to another worker.
#
# If we are living in an nftables world when you read
# this, then this should be totally rethought.
service docker restart
service flannel restart
service kube-proxy restart
