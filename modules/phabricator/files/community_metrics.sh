#!/bin/bash
# send the number of active users on <s>Bugzilla</s> Phabricator
# in the last month to "community metrics" team
# per T81784 - dzahn 20121219
# per T1003 - dzahn,aklapper 20141205
# ! this file is managed by puppet !
# ./modules/phabricator/files/community_metrics.sh

source /etc/phab_community_metrics.conf

#echo "result_activemaniphestusers"
result_activemaniphestusers=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END

SELECT COUNT(DISTINCT authorPHID) FROM maniphest_transaction WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m');

END
)

#echo "result_authors"
result_authors=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(DISTINCT authorPHID) FROM maniphest_task WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m');

END
)

#echo "result_resolvers"
result_resolvers=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(DISTINCT authorPHID) FROM maniphest_transaction WHERE (transactionType="mergedinto" OR
    (transactionType="status" AND (oldValue="\"open\"" OR oldValue="\"stalled\"") AND
    (newValue="\"resolved\"" OR newValue="\"invalid\"" OR newValue="\"declined\""))) AND
    FROM_UNIXTIME(dateCreated,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m');

END
)

#echo "result_projectsboardmove"
result_projectsboardmove=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(DISTINCT (edge.dst)) FROM phabricator_maniphest.edge INNER JOIN phabricator_maniphest.maniphest_transaction WHERE FROM_UNIXTIME(maniphest_transaction.dateModified,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m') AND maniphest_transaction.transactionType = "core:columns" AND edge.type = 41 AND edge.src = maniphest_transaction.objectPHID AND edge.dst = SUBSTR(maniphest_transaction.newValue, INSTR(maniphest_transaction.newValue, 'PHID-PROJ-'), 30);

END
)

#echo "result_taskscreated"
result_taskscreated=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(*) AS '' FROM maniphest_task WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m');

END
)

#echo "result_tasksclosed"
result_tasksclosed=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(*) AS '' FROM maniphest_task WHERE
    FROM_UNIXTIME(closedEpoch,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m');

END
)

#echo "result_tasksopen"
result_tasksopen=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(*) AS '' FROM maniphest_task WHERE (status = "open" OR status = "stalled");

END
)

#echo "result_tasksopen_open"
result_tasksopen_open=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(*) AS '' FROM maniphest_task WHERE status = "open";

END
)

#echo "result_tasksopen_stalled"
result_tasksopen_stalled=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT COUNT(*) AS '' FROM maniphest_task WHERE status = "stalled";

END
)

#echo "results_mediantasksopen_unbreaknow"
result_mediantasksopen_unbreaknow=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT avg(t1.dateCreated) as '' FROM (SELECT @rownum:=@rownum+1 as row_number, d.dateCreated FROM maniphest_task d, (SELECT @rownum:=0) r WHERE (d.priority = "100" AND d.status = "open") ORDER BY d.dateCreated) as t1, (SELECT COUNT(*) AS total_rows FROM maniphest_task d WHERE (d.priority = "100" AND d.status = "open")) as t2 WHERE 1 AND t1.row_number IN ( floor((total_rows+1)/2), floor((total_rows+2)/2));

END
)

#echo "rm_needstriage"
result_mediantasksopen_needstriage=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT avg(t1.dateCreated) as '' FROM (SELECT @rownum:=@rownum+1 as row_number, d.dateCreated FROM maniphest_task d, (SELECT @rownum:=0) r WHERE (d.priority = "90" AND d.status = "open") ORDER BY d.dateCreated) as t1, (SELECT COUNT(*) AS total_rows FROM maniphest_task d WHERE (d.priority = "90" AND d.status = "open")) as t2 WHERE 1 AND t1.row_number IN ( floor((total_rows+1)/2), floor((total_rows+2)/2));

END
)

#echo "rm_high"
result_mediantasksopen_high=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT avg(t1.dateCreated) as '' FROM (SELECT @rownum:=@rownum+1 as row_number, d.dateCreated FROM maniphest_task d, (SELECT @rownum:=0) r WHERE (d.priority = "80" AND d.status = "open") ORDER BY d.dateCreated) as t1, (SELECT COUNT(*) AS total_rows FROM maniphest_task d WHERE (d.priority = "80" AND d.status = "open")) as t2 WHERE 1 AND t1.row_number IN ( floor((total_rows+1)/2), floor((total_rows+2)/2));

END
)

#echo "rm_normal"
result_mediantasksopen_normal=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT avg(t1.dateCreated) as '' FROM (SELECT @rownum:=@rownum+1 as row_number, d.dateCreated FROM maniphest_task d, (SELECT @rownum:=0) r WHERE (d.priority = "50" AND d.status = "open") ORDER BY d.dateCreated) as t1, (SELECT COUNT(*) AS total_rows FROM maniphest_task d WHERE (d.priority = "50" AND d.status = "open")) as t2 WHERE 1 AND t1.row_number IN ( floor((total_rows+1)/2), floor((total_rows+2)/2));

END
)

#echo "rm_low"
result_mediantasksopen_low=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT avg(t1.dateCreated) as '' FROM (SELECT @rownum:=@rownum+1 as row_number, d.dateCreated FROM maniphest_task d, (SELECT @rownum:=0) r WHERE (d.priority = "25" AND d.status = "open") ORDER BY d.dateCreated) as t1, (SELECT COUNT(*) AS total_rows FROM maniphest_task d WHERE (d.priority = "25" AND d.status = "open")) as t2 WHERE 1 AND t1.row_number IN ( floor((total_rows+1)/2), floor((total_rows+2)/2));

END
)

#echo "rm_lowest"
result_mediantasksopen_lowest=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT avg(t1.dateCreated) as '' FROM (SELECT @rownum:=@rownum+1 as row_number, d.dateCreated FROM maniphest_task d, (SELECT @rownum:=0) r WHERE (d.priority = "10" AND d.status = "open") ORDER BY d.dateCreated) as t1, (SELECT COUNT(*) AS total_rows FROM maniphest_task d WHERE (d.priority = "10" AND d.status = "open")) as t2 WHERE 1 AND t1.row_number IN ( floor((total_rows+1)/2), floor((total_rows+2)/2));

END
)

#echo "number of accounts created"
result_accounts_created=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user phabricator_user << END

SELECT COUNT(id) as '' FROM user WHERE FROM_UNIXTIME(dateCreated,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m');

END
)

accountscreated=$(echo $result_accounts_created | tr -d '\n')

activemaniphestusers=$(echo $result_activemaniphestusers | cut -d " " -f3)
authors=$(echo $result_authors | cut -d " " -f3)
resolvers=$(echo $result_resolvers | cut -d " " -f3)

projectsboardmove=$(echo $result_projectsboardmove | cut -d " " -f3)

taskscreated=$(echo $result_taskscreated | cut -d " " -f3)
tasksclosed=$(echo $result_tasksclosed | cut -d " " -f3)

tasksopen=$(echo $result_tasksopen | cut -d " " -f3)
tasksopen_open=$(echo $result_tasksopen_open | cut -d " " -f3)
tasksopen_stalled=$(echo $result_tasksopen_stalled | cut -d " " -f3)

epochnow=$(date +%s)
# regex if we have zero open tasks (can happen for unbreaknow; see T159314):
regex='^[0-9]+$'

mediantasksopen_unbreaknow_epoch=$(echo $result_mediantasksopen_unbreaknow | cut -d " " -f3 | sed 's/\.0000//' | sed 's/\.5000//')
if [[ $mediantasksopen_unbreaknow_epoch =~ $regex ]] ; then
  diff_unbreaknow=$((epochnow-mediantasksopen_unbreaknow_epoch))
  mediantasksopen_unbreaknow=$(echo $((diff_unbreaknow/86400)))
else
  mediantasksopen_unbreaknow=0
fi

mediantasksopen_needstriage_epoch=$(echo $result_mediantasksopen_needstriage | cut -d " " -f3 | sed 's/\.0000//' | sed 's/\.5000//')
diff_needstriage=$((epochnow-mediantasksopen_needstriage_epoch))
mediantasksopen_needstriage=$(echo $((diff_needstriage/86400)))

mediantasksopen_high_epoch=$(echo $result_mediantasksopen_high | cut -d " " -f3 | sed 's/\.0000//' | sed 's/\.5000//')
diff_high=$((epochnow-mediantasksopen_high_epoch))
mediantasksopen_high=$(echo $((diff_high/86400)))

mediantasksopen_normal_epoch=$(echo $result_mediantasksopen_normal | cut -d " " -f3 | sed 's/\.0000//' | sed 's/\.5000//')
diff_normal=$((epochnow-mediantasksopen_normal_epoch))
mediantasksopen_normal=$(echo $((diff_normal/86400)))

mediantasksopen_low_epoch=$(echo $result_mediantasksopen_low | cut -d " " -f3 | sed 's/\.0000//' | sed 's/\.5000//')
diff_low=$((epochnow-mediantasksopen_low_epoch))
mediantasksopen_low=$(echo $((diff_low/86400)))

mediantasksopen_lowest_epoch=$(echo $result_mediantasksopen_lowest | cut -d " " -f3 | sed 's/\.0000//' | sed 's/\.5000//')
diff_lowest=$((epochnow-mediantasksopen_lowest_epoch))
mediantasksopen_lowest=$(echo $((diff_lowest/86400)))

lastmonth=$(date --date="last month" +%Y-%m)

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator monthly statistics - ${lastmonth}" -a "Auto-Submitted: auto-generated" ${rcpt_address}

Hi Community Metrics team,

This is your automatic monthly Phabricator statistics mail.

Accounts created in (${lastmonth}): ${accountscreated}
Active Maniphest users (any activity) in (${lastmonth}): ${activemaniphestusers}
Task authors in (${lastmonth}): ${authors}
Users who have closed tasks in (${lastmonth}): ${resolvers}

Projects which had at least one task moved from one column to another on
their workboard in (${lastmonth}): ${projectsboardmove}

Tasks created in (${lastmonth}): ${taskscreated}
Tasks closed in (${lastmonth}): ${tasksclosed}
Open and stalled tasks in total: ${tasksopen}
* Only open tasks in total: ${tasksopen_open}
* Only stalled tasks in total: ${tasksopen_stalled}

Median age in days of open tasks by priority:

Unbreak now: ${mediantasksopen_unbreaknow}
Needs Triage: ${mediantasksopen_needstriage}
High: ${mediantasksopen_high}
Normal: ${mediantasksopen_normal}
Low: ${mediantasksopen_low}
Lowest: ${mediantasksopen_lowest}

(How long tasks have been open, not how long they have had that priority)

To see the names of the most active task authors:
* Go to https://wikimedia.biterg.io/
* Choose "Phabricator > Overview" from the top bar
* Adjust the time frame in the upper right corner to your needs
* See the author names in the "Submitters" panel

TODO: Numbers which refer to closed tasks might not be correct, as
described in https://phabricator.wikimedia.org/T1003 .

Yours sincerely,
Fab Rick Aytor

(via $(basename $0) on $(hostname) at $(date))
EOF
