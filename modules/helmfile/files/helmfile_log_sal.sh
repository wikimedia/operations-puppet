#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Tcpircbot-related env variables
TCPIRCBOT_HOST=${TCPIRCBOT_HOST:-icinga.wikimedia.org}
TCPIRCBOT_PORT=${TCPIRCBOT_PORT:-9200}

# Allow to explicitely suppress logging to SAL
SUPPRESS_SAL=${SUPPRESS_SAL:-false}

function sal_log {
	if [ -n "${SUDO_USER}" ]; then
		LOG_USER=${SUDO_USER}
	else
		LOG_USER=${USER}
	fi
	echo "!log ${LOG_USER}@${HOSTNAME} helmfile $*" \
		| nc -q 1 "${TCPIRCBOT_HOST}" "${TCPIRCBOT_PORT}" \
		|| (>&2 echo "WARNING: failed to send message to tcpircbot")
}

COMMAND=$1
shift
if [[ ! -z "${COMMAND}" && "${SUPPRESS_SAL}" == "false" ]]; then
	if [[ "${COMMAND}" == "apply" || "${COMMAND}" == "sync" ]]; then
		sal_log "$@"
	fi
fi
