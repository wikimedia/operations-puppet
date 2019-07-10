#!/bin/bash
set -e
HOST=$(hostname)
HELM_HOME=${HELM_HOME:-/etc/helm}
export HELM_HOME

echo -ne "!!!!!!!!! scap-helm is DEPRECATED !!!!!!!!!\n
check out https://wikitech.wikimedia.org/wiki/Migrating_from_scap-helm
for advices for migrating from it\n"

# First argument should be the service
SERVICE=$1
shift
# The second argument is passed to helm and should be the helm command
COMMAND=$1

# We are going to assume that if the user doesn't override the namespace it is the same as the service
NAMESPACE=${NAMESPACE:-$SERVICE}

if [ -z $CLUSTER ]; then
	# Our default clusters
	declare -a CLUSTERS=(eqiad codfw)
else
	CLUSTERS=$CLUSTER
fi
# Tcpircbot-related env variables
TCPIRCBOT_HOST=${TCPIRCBOT_HOST:-icinga.wikimedia.org}
TCPIRCBOT_PORT=${TCPIRCBOT_PORT:-9200}

# Some actions should be logged on the SAL
declare -a LOG_ON_COMMANDS=(install upgrade)

function sal_log {
	if [[ -n "${COMMAND}" && "${LOG_ON_COMMANDS[*]}" =~ "${COMMAND}" ]]; then
		echo "!log ${USER}@${HOST} scap-helm ${SERVICE} $*" \
			| nc -q 1 "${TCPIRCBOT_HOST}" "${TCPIRCBOT_PORT}" \
			|| (>&2 echo "WARNING: failed to send message to tcpircbot")
	fi
}

# Reuse values on updates
if [[ $* =~ 'upgrade' ]]; then
	REUSE_VALUES='--reuse-values'
fi

CLUSTERS_CS=$(IFS=","; echo "${CLUSTERS[*]}")
sal_log "$* [namespace: ${NAMESPACE}, clusters: ${CLUSTERS_CS}]"
for CLUSTER in "${CLUSTERS[@]}"
do
	echo "### cluster ${CLUSTER}"
	KUBECONFIG="/etc/kubernetes/${SERVICE}-${CLUSTER}.config" helm --tiller-namespace=${NAMESPACE} "$@" $REUSE_VALUES
	sal_log "cluster ${CLUSTER} completed"
done
sal_log "finished"
