#/bin/bash

/usr/bin/logger -t ${0} "restart firewall components post ferm management"

# Ferm expects to handle all firewall state
# and that does not mesh well with dynamic chain management.
# We tell the k8s stack here to restart
#
# This should be no more invasive than a rescheduling
# of a POD to another worker.
#
# If we are living an nftables world when you read
# this, then this should be totally rethought.
sudo service docker restart
sudo service flannel restart
sudo service kube-proxy restart
