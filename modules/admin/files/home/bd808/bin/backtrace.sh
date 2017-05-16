#!/usr/bin/env bash
# Generate a backtrace using gdb.
# $Id: backtrace.sh 288 2010-07-27 20:41:02Z bpd $

usage() {
    cat<<EOF
Usage: ${0} program_name [program_args]

Trace a given program using gdb.

EOF
}

log() {
    echo "${*}" 1>&2
}

die() {
    usage
    log 'error:' ${*}'.'
    exit 1
}


#---------------------------------------------------------------------
test "x${*}" = "x" && die 'no process given'

LOG="/tmp/gdb-`basename ${1}`.txt"
log "outputting trace to '${LOG}'"

exec gdb -batch-silent \
    -ex 'set logging overwrite on' \
    -ex "set logging file ${LOG}" \
    -ex 'set logging on' \
    -ex 'handle SIG33 pass nostop noprint' \
    -ex 'set pagination 0' \
    -ex 'run' \
    -ex 'backtrace full' \
    -ex 'info registers' \
    -ex 'x/16i $pc' \
    -ex 'thread apply all backtrace' \
    -ex 'quit' \
    --args ${*} \
    < /dev/null
