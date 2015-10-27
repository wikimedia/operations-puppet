#!/bin/bash

#check_mailman_queue
#~~~~~~~

#:copyright: (c) 2014 Matanya Moses, 2015 Daniel Zahn
#:license: Apache License 2.0.

# Usage:
# /files/icinga/check_mailman_queue <queue limit>

mailman_base="/var/lib/mailman/qfiles"
FILES="$mailman_base/bounces $mailman_base/in $mailman_base/virgin"

queue_limit_bounces=$1
queue_limit_in=$2
queue_limit_virgin=$3

critqueues=0
debug=false

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then echo "usage: ./check_mailman_queue <queue limit bounces> <queue limit in> <queue limit virgin>"; exit 3; fi

for f in $FILES
do
    if [ -d $f ]
        then
        queue_size=$(ls $f|wc -l)
        if $debug; then echo "${f}: ${queue_size}"; fi

        if [ $queue_size -gt $queue_limit_bounces ] || [ $queue_size -gt $queue_limit_in ] || [ $queue_size -gt $queue_limit_virgin ]
            then
            if $debug; then echo "CRIT: ${f}: ${queue_size} (thresholds: bounces: ${queue_limit_bounces} in: ${queue_limit_in} virgin: ${queue_limit_virgin}"; fi
            ((critqueues++))
            if $debug; then echo "crit queues: ${critqueues}"; fi
        fi
    else
       echo "UNKNOWN : Unable to open ${f}"
       exit 3
    fi
done


if [ $critqueues -ge 1 ]
    then
        echo "CRITICAL: ${critqueues} mailman queue(s) above limits (thresholds: bounces: ${queue_limit_bounces} in: ${queue_limit_in} virgin: ${queue_limit_virgin})"
        exit 2
    else
        echo "OK: mailman queues are below the limits."
        exit 0
fi

echo "UNKNOWN: check check_mailman_queue"
exit 3
