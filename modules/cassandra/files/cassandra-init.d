#!/bin/sh

# Replace stock Cassandra init (https://phabricator.wikimedia.org/T127365).

. /lib/lsb/init-functions

case "$1" in
  stop)
    if [ -s /var/run/cassandra/cassandra.pid ]; then
      log_daemon_msg "Stopping Cassandra"
      kill $(cat /var/run/cassandra/cassandra.pid)
      log_end_msg 0
    fi
    ;;
esac

exit 0
