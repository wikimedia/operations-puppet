#!/bin/bash
#
# Determine if a node is actually ready for use with haproxy

set -euo pipefail

function usage {
    cat << EOF
Usage: $(basename -- "$0") <config_file>

config_file must actually exist.
EOF
}


# if a disabled file is present, return 404, for manual dropping from cluster
if [ -e "/tmp/galera.disabled" ]; then
    # Shell return-code is 1
    echo -en "HTTP/1.1 404 Not Found\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 24\r\n"
    echo -en "\r\n"
    echo -en "DB is manually disabled.\r\n"
    echo -en "\r\n"
    exit 1
fi

# By default, assume we are running as prometheus, which has enough perms.
DEFAULTS_FILE=${1:-/var/lib/prometheus/.my.cnf}

# Make sure ERR_LOG dir exists and is writable for this.
ERR_LOG="/var/log/nodecheck/err.log"

if [[ ! -f $DEFAULTS_FILE ]]; then
    usage
    exit 1
fi
TIMEOUT=10

# The command uses vertical output, so it requires a tail -1
CMD="mysql --defaults-file=$DEFAULTS_FILE -nNE --connect-timeout=$TIMEOUT"

#
# Check galera node state
#
WSREP_READY=$($CMD -e "SHOW STATUS LIKE 'wsrep_ready';" 2>>${ERR_LOG} | tail -1 2>>${ERR_LOG})

if [[ $WSREP_READY == "ON" ]]
then
    READ_ONLY=$($CMD -e "SHOW GLOBAL VARIABLES LIKE 'read_only';" 2>>${ERR_LOG} | tail -1 2>>${ERR_LOG})

    if [[ "${READ_ONLY}" == "ON" ]];then
        # If read only, do not use.
        echo -en "HTTP/1.1 503 Service Unavailable\r\n"
        echo -en "Content-Type: text/plain\r\n"
        echo -en "Connection: close\r\n"
        echo -en "Content-Length: 20\r\n"
        echo -en "\r\n"
        echo -en "Node is read-only.\r\n"
        echo -en "\r\n"
        exit 1
    fi
    # All is well! Use this node
    echo -en "HTTP/1.1 200 OK\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 23\r\n"
    echo -en "\r\n"
    echo -en "Galera node is ready.\r\n"
    echo -en "\r\n"
    exit 0
else
    # wsrep_ready is not ON, so the node is not going to work
    echo -en "HTTP/1.1 503 Service Unavailable\r\n"
    echo -en "Content-Type: text/plain\r\n"
    echo -en "Connection: close\r\n"
    echo -en "Content-Length: 16\r\n"
    echo -en "\r\n"
    echo -en "DO NOT USE ME.\r\n"
    echo -en "\r\n"
    exit 1
fi
