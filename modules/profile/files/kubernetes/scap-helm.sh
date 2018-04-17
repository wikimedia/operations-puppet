#!/bin/bash

set -e

HELM_HOME=${HELM_HOME:-/etc/helm}
export HELM_HOME

# First argument should be the service
SERVICE=$1
shift

# We are going to assume that if the user doesn't override the namespace it is the same as the service
NAMESPACE=${NAMESPACE:-$SERVICE}

if [ -z $CLUSTER ]; then
	# Our default clusters
	declare -a CLUSTERS=(eqiad codfw)
else
	CLUSTERS=$CLUSTER
fi

if [[ $* =~ 'upgrade' ]]
then
	REUSE_VALUES='--reuse-values'
fi


for CLUSTER in "${CLUSTERS[@]}"
do
	KUBECONFIG="/etc/kubernetes/${SERVICE}-${CLUSTER}.config" helm --tiller-namespace=${NAMESPACE} "$@" $REUSE_VALUES
done
