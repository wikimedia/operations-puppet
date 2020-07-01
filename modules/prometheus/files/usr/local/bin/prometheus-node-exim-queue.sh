#!/bin/bash

set -e

OUTFILE='/var/lib/prometheus/node.d/exim_queue.prom'

if [ "$(id -u)"  != "0" ] ; then
	echo "root required!" >&2
	exit 1
fi

queue_length=$(mailq 2>/dev/null | grep '<' | wc -l || echo 0)
frozen_length=$(mailq 2>/dev/null | grep '<' | grep '\*\*\* frozen \*\*\*' | wc -l || echo 0)

echo "
# HELP exim_queue_length Exim queue length
# TYPE exim_queue_length gauge
exim_queue_length $queue_length
# HELP exim_queue_length_frozen Exim queue length for frozen messages
# TYPE exim_queue_length_frozen gauge
exim_queue_length_frozen $frozen_length
" > $OUTFILE.$$

# lets try to be atomic
chown prometheus:prometheus $OUTFILE.$$ 2>/dev/null
mv $OUTFILE.$$ $OUTFILE 2>/dev/null
