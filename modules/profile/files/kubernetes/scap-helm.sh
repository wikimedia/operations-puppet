#!/bin/bash

set -e

HELM_HOME=${HELM_HOME:-/etc/helm}
export HELM_HOME

# First argument should be the service
SERVICE=$1
shift

# We are going to assume that if the user doesn't override the namespace it is the same as the service
NAMESPACE=${NAMESPACE:-$SERVICE}

if [ -n $CLUSTER ]; then
	CLUSTERS=$CLUSTER
else
	# Our default clusters
	declare -a CLUSTERS=(eqiad codfw)
fi

for CLUSTER in "${CLUSTERS[@]}"
do
	KUBECONFIG="/etc/kubernetes/${SERVICE}-${CLUSTER}.config" helm --tiller-namespace=${NAMESPACE} $*
done
