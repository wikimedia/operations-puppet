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

# Excluding some lines to reduce the size of the output to not exceed the NRPE
# hard coded message limit of 1k.
EXCLUDE_PATTERN='(Heads|Sectors Per Track|Cylinders|Unique Identifier|Logical Drive Label):'
OUTPUT=""
EXIT_CODE=0

# Gather the controllers slots while exposing the exit code to the parent shell
set +e
CONTROLLERS="$(/usr/bin/sudo /usr/sbin/hpssacli controller all show | grep -Eo 'Slot [0-9] ' | cut -d' ' -f2; exit "${PIPESTATUS[0]}")"
EXIT_CODE=$((EXIT_CODE + ${?}))
set -e

while read -r CONTROLLER; do
    # Append the output while exposing the exit code of the hpssacli command to the parent shell
    set +e
    OUTPUT="${OUTPUT}$(/usr/bin/sudo /usr/sbin/hpssacli controller slot="${CONTROLLER}" ld all show detail | grep -Ev "${EXCLUDE_PATTERN}"; exit "${PIPESTATUS[0]}")\n"
    # Sum all exit codes so that the check fails if any of them fail
    EXIT_CODE=$((EXIT_CODE + ${?}))
    set -e
done <<< "${CONTROLLERS}"

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

exit "${EXIT_CODE}"
