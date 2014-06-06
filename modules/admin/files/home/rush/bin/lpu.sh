#!/bin/bash
#prints time since last recorded puppet update
#you know...for debugging
last=`grep last_run /var/lib/puppet/state/last_run_summary.yaml | awk {'print $2'}`
now=`date +%s`
SECONDS=`expr $now - $last`
MIN=`expr $SECONDS / 60`
HOURS=`expr $MIN / 60`
DAYS=`expr $HOURS / 24`

echo "Since last puppet update"
echo 'seconds: '$SECONDS
echo 'minutes: '$MIN
if [ $HOURS -gt 0 ]; then
    echo 'hours: '$HOURS
fi

if [ $HOURS -gt 0 ]; then
    echo 'hours: '$HOURS
fi

if [ $DAYS -gt 0 ]; then
    echo 'days: '$DAYS
fi
