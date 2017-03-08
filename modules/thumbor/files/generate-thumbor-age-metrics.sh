#!/bin/bash

/bin/systemctl show -p Id -p ExecMainStartTimestampMonotonic thumbor@* | /usr/bin/awk -v RS="" -v OFS="=" -v HOSTNAME=$(/bin/hostname) '{print "thumbor."HOSTNAME".process."substr($2,12,4)".start_timestamp_monotonic:"substr($1,33)"|g"}'