#!/bin/bash
set -euo pipefail
# Daily cronjob to restart php-fpm if the free opcache is below a certain level.
# Service name
SERVICE="$1"
# Minimum opcache free MB.
MIN_FREE="$2"

FREE=$(php7adm /opcache-info | jq .memory_usage.free_memory/1024/1024 2>&1)
FREE_MB=${FREE%.*}
if [ "$MIN_FREE" -ge "$FREE_MB" ]; then
    echo "Restarting ${SERVICE}: free opcache $FREE_MB MB"
   "/usr/local/sbin/restart-$SERVICE"
else
    echo "NOT restarting ${SERVICE}: free opcache $FREE_MB MB"
fi
