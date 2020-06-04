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

function check_weight {
    # Check that none of the selected entries has weight 0
    host=$1
    service=$2
    selector="name=$host"
    if [ "$service" != "all services" ]; then
        selector="${selector},service=${service}"
    fi
    if confctl select "$selector" get | jq -e ".[\"$host\"] | select(.pooled != \"yes\") | select(.weight == 0)" > /dev/null; then
        printf "\033[0;31mYou cannot pool a node where weight is equal to 0\033[0m\n"
        exit 2
    fi
}

if [ ! -x /usr/bin/confctl ]; then
    echo "/usr/bin/confctl not found"
    exit 1
fi

# Get message to print on screen.
case $action in
    "pool")
    check_weight "$host" "$service"
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
