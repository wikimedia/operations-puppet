#!/bin/bash
#
# Determine if a node is actually ready for use with haproxy

set -euo pipefail

# Make sure ERR_LOG dir exists and is writable for this.
ERR_LOG="/var/log/nodecheck/err.log"
exec 2>>$ERR_LOG
echo $(/usr/bin/date +%s) beginning health check >> ${ERR_LOG}

function usage {
    cat << EOF
Usage: $(basename -- "$0") <config_file>

config_file must actually exist.
EOF
}


# if a disabled file is present, return 404, for manual dropping from cluster
if [ -e "/tmp/galera.disabled" ]; then
    # Shell return-code is 1
    cat <<EOR
HTTP/1.1 404 Not Found
Content-Type: text/plain
Connection: close
Content-Length: 24

DB is manually disabled.

EOR
    echo $(/usr/bin/date +%s) returned 404 >> ${ERR_LOG}
    exit 1
fi

# By default, assume we are running as prometheus, which has enough perms.
DEFAULTS_FILE=${1:-/var/lib/prometheus/.my.cnf}


if [[ ! -f $DEFAULTS_FILE ]]; then
    usage
    echo $(/usr/bin/date +%s) returned NOTHING >> ${ERR_LOG}
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
        cat <<EOR
HTTP/1.1 503 Service Unavailable
Content-Type: text/plain
Connection: close
Content-Length: 20

Node is read-only.

EOR
        echo $(/usr/bin/date +%s) returned 503 >> ${ERR_LOG}
        exit 1
    fi
    # All is well! Use this node
    cat <<EOR
HTTP/1.1 200 OK
Content-Type: text/plain
Connection: close
Content-Length: 23

Galera node is ready.

EOR
    echo $(/usr/bin/date +%s) returned 200 >> ${ERR_LOG}
    exit 0
else
    # wsrep_ready is not ON, so the node is not going to work
    cat <<EOR
HTTP/1.1 503 Service Unavailable
Content-Type: text/plain
Connection: close
Content-Length: 16

DO NOT USE ME.

EOR
    echo $(/usr/bin/date +%s) returned 503 >> ${ERR_LOG}
    exit 1
fi
