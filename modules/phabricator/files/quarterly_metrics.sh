#!/bin/bash
# Basic quarterly statistics of Phabricator used for
# https://www.mediawiki.org/wiki/Technical_Community_Newsletter
# per T337387 - aklapper 20230523
# SPDX-License-Identifier: Apache-2.0
# ! this file is managed by puppet !
# ./modules/phabricator/files/quarterly_metrics.sh

source /etc/phab_quarterly_metrics.conf

#echo "result_tasks_created"
result_tasks_created=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(dateCreated) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 3 MONTH,'%Y%m');

END
)

#echo "result_tasks_closed"
result_tasks_closed=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(closedEpoch) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 3 MONTH,'%Y%m');

END
)

#echo "result_task_authors"
result_tasks_authors=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(DISTINCT (authorPHID)) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 3 MONTH,'%Y%m');

END
)

#echo "result_tasks_closers"
result_tasks_closers=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(DISTINCT (closerPHID)) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 3 MONTH,'%Y%m');

END
)

taskscreated=$(echo $result_tasks_created | sed 's/[^0-9]*//g')
tasksclosed=$(echo $result_tasks_closed | sed 's/[^0-9]*//g')
tasksauthors=$(echo $result_tasks_authors | sed 's/[^0-9]*//g')
tasksclosers=$(echo $result_tasks_closers | sed 's/[^0-9]*//g')

lastquarter=$(date +"Q$(expr $(expr $(date -d '-1 month' +%m) - 1) / 3 + 1)/%Y")

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator quarterly statistics - ${lastquarter}" ${rcpt_address}

This is the automatic quarterly Phabricator statistics mail used
for https://www.mediawiki.org/wiki/Technical_Community_Newsletter

=== Phabricator and Gerrit ===

* [[mw:Phabricator|Phabricator]]: Number of tasks created in ${lastquarter}: ${taskscreated}
* Phabricator: Number of tasks closed in ${lastquarter}: ${tasksclosed}
* Phabricator: Number of different people who created tasks in ${lastquarter}: ${tasksauthors}
* Phabricator: Number of different people who closed tasks in ${lastquarter}: ${tasksclosers}
* [[mw:Gerrit|Gerrit]]: 
** Go to https://wikimedia.biterg.io/
** Select "Gerrit" from the top bar
** Adjust the time frame in the upper right corner to cover the last quarter
** Select "Independent" in the "Organizations" pie chart to filter on affiliation

Yours sincerely,
Fab Rick Aytor

(via $(basename $0) on $(hostname) at $(date))
EOF
