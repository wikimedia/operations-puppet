#!/bin/bash

HOSTNAME=`/bin/hostname`
PRIVATE_DATA="/usr/local/sbin/check_private_data.py"
REPORTS_DIR='/var/log'
REPORT_NAME=`echo private_data_report_$(hostname)_$(date +"%Y%m%d").txt`

if [ ! -f "$PRIVATE_DATA" ]
then
	echo "${PRIVATE_DATA} is not present"
	exit 1
fi

# run the script

if [ $hostname == db1069 ]
then
    echo "This script will not work on db1069 as it has multiple instances"
    exit 1
fi

$PRIVATE_DATA 2>&1 > $REPORTS_DIR/$REPORT_NAME

DATA=`/bin/cat $REPORTS_DIR/$REPORT_NAME | /bin/egrep -v "^--" | /usr/bin/wc -l`

if [ $DATA -gt 0 ]
then
    echo "Private data detected at $HOSTNAME check: /var/log/private_data_report_$(hostname)_$(date +"%Y%m%d").txt"  | /usr/bin/mail -s "Private data found at $HOSTNAME" marostegui@wikimedia.org
fi

exit 0
