#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Nagios/Icinga check command for dbctl, MediaWiki database config in etcd.
# See also https://wikitech.wikimedia.org/wiki/Dbctl

# Returns CRITICAL (2) on any uncommitted dbctl diffs, or on any error.
# Returns OK (0) otherwise.

set -uf

dbctl config diff --quiet
case "$?" in
    0)
        echo "OK - no diffs"
        exit 0
    ;;
    1)
        echo "CRITICAL - Uncommitted dbctl configuration changes, check dbctl config diff"
        exit 2
    ;;
    *)
        echo "CRITICAL - Unknown error executing dbctl config diff"
        exit 2
    ;;
esac