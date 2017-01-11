#!/bin/bash

state_path=$1
prometheus_path=$2

timestamp=`grep ^timestamp $state_path | sed -e 's/^timestamp=//' -e 's/\\\//g'`
lag=$(( `date "+%s"` - `date "+%s" --date=${timestamp}` ))
echo "osm_sync_lag" $lag > $prometheus_path.$$
mv $prometheus_path.$$ $prometheus_path
