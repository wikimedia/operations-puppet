#!/bin/sh

# Watch error log spam.  See /usr/bin/logspam for implementation details.

. /etc/profile.d/mw-log.sh
watch -n 10 sh -c "logspam | sort -nr | head -50"
