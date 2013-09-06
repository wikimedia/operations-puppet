#!/bin/bash

seq=$(echo $1 | cut -d':' -f 1)
controller=$(($seq / 8))
disk=$((seq % 8))

if [ -n "$2" ]; then
	echo "c${controller}t${disk}d0s$(($2 - 1))"
else
	echo "c${controller}t${disk}d0"
fi
