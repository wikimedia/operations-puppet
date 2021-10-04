#!/bin/bash

NODE_GROUPS=`/usr/sbin/gnt-group list --output name --no-headers`

for group in $NODE_GROUPS;
do
	hbal -L -G $group -X &
done
wait
