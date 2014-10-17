#!/bin/bash

DATE=$(date '+%Y%m%d')

for i in labswiki keystone nova 
do
        nice -n 19 mysqldump --single-transaction -u root ${i} -c | nice -n 19 gzip -9 > /a/backup/${i}-${DATE}.sql.gz
done

for i in glance mysql
do
        nice -n 19 mysqldump -u root ${i} -c | nice -n 19 gzip -9 > /a/backup/${i}-${DATE}.sql.gz
done
