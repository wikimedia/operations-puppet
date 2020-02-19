#!/bin/bash
set -u

action=$(basename "${0}")

# Mangle service name, used for printing too.
_service="${1:-all services}"
# Keep compatibility with the old model allowing to select any generic tag
service="${_service//service=/}"

# Break compatibility with selecting anything else than services
if [[ $service =~ "=" ]]; then
    echo "Selection of any tag other than 'service' is not allowed"
    exit 3
fi

host=$(hostname -f)

# Get message to print on screen.
case $action in
    "pool")
    echo "Pooling ${service} on ${host}"
    ;;
    "depool")
    echo "Depooling ${service} on ${host}"
    ;;
    "decommission")
    echo "Decommissioning ${service} on ${host}"
    ;;
    *)
    echo "Invalid command: ${0}"
    exit 2
esac


function do_action() {
    if [ "${1}" == "all services" ]; then
        confctl --quiet "${action}" 2> /dev/null
    else
        confctl --quiet "${action}" --service "${1}" 2> /dev/null
    fi
}


do_action "${service}"
