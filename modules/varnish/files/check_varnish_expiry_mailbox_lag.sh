#!/bin/sh

cmd="/usr/bin/varnishstat -t off -1"

if ! $cmd > /dev/null 2>&1;
then
    echo "UNKNOWN: cannot run varnishstat"
    exit 3
fi

$cmd | awk '
/exp_mailed/ { m = $2 }
/exp_received/ { r = $2 }

END {
    msg = "expiry mailbox lag is "
    lag = m - r

    if (lag > 10000) {
        print "CRITICAL: " msg lag
        exit 2
    }
    else if (lag > 1000) {
        print "WARNING: " msg lag
        exit 1
    } else {
        print "OK: " msg lag
        exit 0
    }
}'
