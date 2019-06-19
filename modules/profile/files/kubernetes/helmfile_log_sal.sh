#!/bin/bash

# Tcpircbot-related env variables
TCPIRCBOT_HOST=${TCPIRCBOT_HOST:-icinga.wikimedia.org}
TCPIRCBOT_PORT=${TCPIRCBOT_PORT:-9200}

function sal_log {
		echo "!log ${USER}@${HOST} helmfile $*" \
			| nc -q 1 "${TCPIRCBOT_HOST}" "${TCPIRCBOT_PORT}" \
			|| (>&2 echo "WARNING: failed to send message to tcpircbot")
}

COMMAND=$1
shift
if [[ ! -z "${COMMAND}" ]]; then
	if [[ "${COMMAND}" == "apply" || "${COMMAND}" == "sync" ]]; then
		sal_log "$@"
	fi
fi