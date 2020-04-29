#!/bin/bash

set -e

ADDRESS="rancid-core@wikimedia.org"
INFO="To see the actual diff for a given set of devices, from a cumin host run: homer DEVICES diff"

set +e
DIFF="$(/usr/local/bin/homer --quiet '*' diff --omit-diff 2>&1)"
EXIT="${?}"
set -e

if [[ "${EXIT}" -eq "0" ]]; then
    echo "No diff found"
    exit 0
fi

echo "Found diff for some devices, sending email to ${ADDRESS}"
echo -e "${DIFF}\n\n${INFO}" | mail -s "[Homer] Device live config differs from committed one" "${ADDRESS}"

# Do not make the systemd timer fail even if the email was sent
