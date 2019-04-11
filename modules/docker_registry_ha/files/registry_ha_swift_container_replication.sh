#!/bin/bash
set -uo pipefail

function usage {
    echo -ne "Usage: $0 [-x|-t] -a /path/to/account.file \n\
                 -r swift_replication_configuration (//REPLICATION_CLUSTER/cluster/AUTH/swift_container) \n\
                 -k swift_replication_key \n\
                 -c swift_container"
}

function create_container {
    local account_file=$1
    local swift_container=$2
    local swift_replication_configuration=$3
    local swift_replication_key=$4

    source "${account_file}" && swift post \
                    -t "${swift_replication_configuration}" \
                    -k "${swift_replication_key}" "${swift_container}"
    logger -t "docker_registry_ha_swift" "Replicated swift container ${swift_container} created."

}

function check_container {
    local account_file=$1
    local swift_container=$2

    source "${account_file}" && swift stat "${swift_container}"
    logger -t "docker_registry_ha_swift" "checked if ${swift_container} exists."

}

function main {
    local account_file
    local swift_replication_configuration
    local swift_replication_key
    local swift_container
    local create=0
    local check=0

    while getopts "xta:r:k:c:" o; do
        case "${o}" in
            x)
                create=1
                ;;
            t)
                check=1
                ;;
            a)
                account_file=${OPTARG}
                if [ ! -f "${account_file}" ];  then
                    echo "Cannot access account_file"
                    usage
                    exit 1
                fi
                ;;
            r)
                swift_replication_configuration="${OPTARG}"
                ;;
            k)
                swift_replication_key="${OPTARG}"
                ;;
            c)
                swift_container="${OPTARG}"
                ;;
            *)
                usage
                ;;
        esac
    done
    shift $((OPTIND-1))

    # validating parameters
    if [ -z "${account_file+x}" ]; then echo "account_file is unset"; usage; exit 2 ; fi
    if [ -z "${swift_container+x}" ]; then echo "swift_container is unset"; usage; exit 2 ; fi
    if [ ${create} -eq 0 ] && [ ${check} -eq 0 ]; then
        echo "either check or create a container"
        usage
        exit 2
    fi

    command -v swift >/dev/null 2>&1 || { echo >&2 "I require swift cli but it's not installed.  Aborting."; exit 1; }
    if [ ${create} -eq 1 ]; then
        if [ -z "${swift_replication_configuration+x}" ]; then echo "swift_replication_configuration is unset"; usage; exit 2 ; fi
        if [ -z "${swift_replication_key+x}" ]; then echo "swift_replication_key is unset"; usage; exit 2 ; fi
        create_container "${account_file}" "${swift_container}" "${swift_replication_configuration}" "${swift_replication_key}"
    else
        check_container "${account_file}" "${swift_container}"
    fi

}

main "$@"