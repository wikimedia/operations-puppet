#!/bin/bash

PRIVATE_DATA="/usr/local/sbin/check_private_data.py"
REPORTS_DIR='/var/log'
REPORT_NAME=`echo private_data_report_$(hostname)_$(date +"%Y%m%d").txt`

# remove older than 7 days files
if [ ! -f "$PRIVATE_DATA" ]
then
	echo "${PRIVATE_DATA} is not present"
	exit 1
fi

find $REPORTS_DIR/$REPORT_NAME -type f -mtime 7 -exec rm -f {} \;

# run the script

$PRIVATE_DATA 2>&1 > $REPORTS_DIR/$REPORT_NAME

DATA=`cat $REPORTS_DIR/$REPORT_NAME | grep -v "-" | wc -l`

if [ $DATA -gt 0 ]
then
    echo "Private data detected at `hostname` check: /var/log/private_data_report_$(hostname)_$(date +"%Y%m%d").txt"  | mail -s "Private data found at `hostname`" marostegui@wikimedia.org
fi

exit 0
