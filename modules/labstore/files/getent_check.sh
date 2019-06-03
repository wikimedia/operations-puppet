#! /bin/bash

# Plant a sigalarm and catch it
# for a hard timeout

timeout() {
    echo "CRITICAL: getent group tools.admin timed out (>1s)"
    exit 2
}


trap timeout 14
sleep 1 && kill -14 $$ &

# Try to fetch a known group via LDAP
/usr/bin/useldap /usr/bin/getent group tools.admin >/dev/null 2>&1
rv=$?

# At this point, the command returns (worked or failed, so
# remove the trap and wait for the timeout to pass.

trap '' 14
wait

# Not timed out, but could still have failed.

if [ $rv -ne 0 ]; then
    echo "CRITICAL: getent group tools.admin failed"
    exit 2
fi

echo "OK: getent group returns within a second"
exit 0
