#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Check that all entries in the orchestrator host resolve cache are FQDNs.
# Entries where hostname != resolved_hostname indicate a non-FQDN in the cache.

output=$(orchestrator -c show-resolve-hosts -quiet 2>&1)
exit_code=$?

if [ "${exit_code}" -ne 0 ]; then
    echo "CRITICAL: orchestrator show-resolve-hosts failed: ${output}"
    exit 2
fi

non_fqdn=$(echo "${output}" | awk '$1 != $2 {print}')

if [ -n "${non_fqdn}" ]; then
    count=$(echo "${non_fqdn}" | wc -l | tr -d ' ')
    echo "CRITICAL: ${count} non-FQDN entries in orchestrator resolve cache:"
    echo "${non_fqdn}"
    exit 2
fi

echo "OK: all orchestrator resolve cache entries are FQDNs"
exit 0
