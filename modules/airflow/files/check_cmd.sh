#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Runs a shell command as an icinga check.
# The retval of the command determines the status of the check.
#
# Examples:
#   check_cmd test -e /tmp/file
#   check_cmd curl --silent ...

output=$("${@}")
exitval=$?

if [ $exitval -ne 0 ]; then
    echo "CRITICAL: $* did not succeed"
    echo "${output}"
    exit 2
else
    echo "OK: $* succeeded"
    echo "${output}"
    exit 0
fi
