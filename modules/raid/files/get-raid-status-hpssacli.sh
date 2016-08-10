#!/bin/bash

set -e

function usage() {
    cat <<EOF
usage: ${0} [-c]

Print a summarized status of all detected HP Raid controllers

optional arguments:
  -c          compress with zlib the summary to overcome NRPE output limits.
  -h          show this help message and exit
EOF

    exit "${1}"
}

COMPRESS=0
if [[ -n "${1}" ]]; then
    case "${1}" in
        "-c") COMPRESS=1;;
        "-h") usage 0;;
        *)
            echo "Invalid parameter '${1}'"
            usage 1
            ;;
    esac
fi

OUTPUT=""
while read -r CONTROLLER; do
    OUTPUT="${OUTPUT}$(/usr/bin/sudo /usr/sbin/hpssacli controller slot="${CONTROLLER}" ld all show detail)\n"
done < <(/usr/bin/sudo /usr/sbin/hpssacli controller all show | egrep -o 'Slot [0-9] ' | cut -d' ' -f2)

PYTHON_SCRIPT="
import sys
import zlib

# NRPE doesn't handle NULL bytes, encoding them.
# Given the specific domain there is no need of a full yEnc encoding
print(zlib.compress(sys.stdin.read()).replace('\x00', '###NULL###'))"

if [[ "${COMPRESS}" -eq "1" ]]; then
    echo -e "${OUTPUT}" | python -c "${PYTHON_SCRIPT}"
else
    echo -e "${OUTPUT}"
fi
