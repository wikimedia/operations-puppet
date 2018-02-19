#!/bin/bash
set -u

action=$(basename "${0}")
service="${1:-all services}"
host=$(hostname -f)
old_action=""
msg=""

# Get message to print on screen, and the old action
case $action in
    "pool")
    old_action="set/pooled=yes"
    msg="Pooling ${service} on ${host}"
    ;;
    "depool")
    old_action="set/pooled=no"
    msg="Depooling ${service} on ${host}"
    ;;
    "drain")
    old_action="set/weight=0"
    msg="Draining ${service} on ${host}"
    ;;
    "decommission")
    old_action="set/pooled=inactive"
    msg="Decommissioning ${service} on ${host}"
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

function do_old_action() {
    if [ "${1}" == "all services" ]; then
        confctl --quiet --find --action $old_action "${host}"
    else
        confctl --quiet select "service=${1},name=${host}" $old_action
    fi
}

echo "${msg}"
do_action "${service}"
# Compatibility with confctl < 1.0
if [ $? -eq 2 ]; then
    do_old_action "${service}"
fi
