#!/bin/bash

for i in `mysql -BNe 'show databases'`
do
        if [ "${i}" == "information_schema" ]
        then   
                continue
        fi
        nice -n 19 mysqldump -u root ${i} -c | nice -n 19 gzip -9 > /a/backup/${i}-$(date '+%Y%m%d').sql.gz
done
