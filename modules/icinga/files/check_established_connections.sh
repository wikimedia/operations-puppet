#!/bin/sh
# This plugin tests whether the number of established TCP connections with the
# given host:port is greater or equal than a certain value

host="$1"
dport="$2"
min="$3"

/bin/ss -t state established dst $host dport = :$dport | awk "
NR>1 { count++ }
END {
    msg = \"connections established with $host:$dport (min=$min)\"

    if (count >= $min) {
        printf \"OK: %d %s\n\", count, msg
        exit 0
    }

    printf \"CRITICAL: %d %s\n\", count, msg
    exit 2
}"
