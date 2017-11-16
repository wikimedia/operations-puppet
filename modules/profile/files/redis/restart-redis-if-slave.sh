#!/bin/bash
set -e

# Random sleep to stagger execution of this script
sleep $(($RANDOM % 600))

# Check if currently a slave
for instance in "$@";
do
    _config="/etc/redis/tcp_${instance}.conf"
    authpass=$(awk '{if ($1 == "requirepass") print $2}' "$_config")
    if redis-cli -h 127.0.0.1 -p "$instance" -a "$authpass" INFO replication | grep -q role:slave; then
        systemctl restart "redis-instance-tcp_${instance}.service"
        # Avoid multiple SYNC requests to the master shards at the same time
        # (that might hit disk performances and slow down the master host).
        sleep 180
    fi
done
