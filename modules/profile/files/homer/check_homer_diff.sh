#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e

ADDRESS="rancid-core@wikimedia.org"
INFO="To see the actual diff for a given set of devices, from a cumin host run: homer DEVICES diff"

set +e
DIFF="$(/usr/local/bin/homer --quiet 'status:active' diff --omit-diff 2>&1)"
EXIT="${?}"
set -e

if [[ "${EXIT}" -eq "0" ]]; then
    echo "No diff found"
    exit 0
fi

if [[ "${EXIT}" -eq "99" ]]; then
    SUBJECT="Device live config differs from committed one"
else
    SUBJECT="Live config check failed to run"
fi

echo "${SUBJECT}, sending email to ${ADDRESS}"
echo -e "${DIFF}\n\n${INFO}" | mail -s "[Homer] ${SUBJECT}" "${ADDRESS}"

# Do not make the systemd timer fail if the email was sent but fail if the email send step fails.
