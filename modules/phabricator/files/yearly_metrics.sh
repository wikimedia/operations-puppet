#!/bin/bash
# Basic yearly statistics of Phabricator used for
# early January email to wikitech-l mailing list
# per T337388 - aklapper 20230523
# SPDX-License-Identifier: Apache-2.0
# ! this file is managed by puppet !
# ./modules/phabricator/files/yearly_metrics.sh

source /etc/phab_yearly_metrics.conf

#echo "result_tasks_created"
result_tasks_created=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(dateCreated) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m');
END
)

#echo "result_tasks_closed"
result_tasks_closed=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(closedEpoch) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m');
END
)

#echo "result_active_users"
result_active_users=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(DISTINCT (authorPHID)) FROM phabricator_maniphest.maniphest_transaction WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m');
END
)

#echo "result_tasks_authors"
result_tasks_authors=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(DISTINCT (authorPHID)) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(dateCreated,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m');
END
)

#echo "result_tasks_closers"
result_tasks_closers=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END

SELECT COUNT(DISTINCT (closerPHID)) FROM phabricator_maniphest.maniphest_task WHERE
    FROM_UNIXTIME(closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m');
END
)

#echo "result_tasks_authors_top20"
result_tasks_authors_top20=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT usr.username AS user, COUNT(usr.username) AS created
    FROM phabricator_user.user usr JOIN phabricator_maniphest.maniphest_task tsk
    WHERE tsk.authorPHID = usr.phid
    AND FROM_UNIXTIME(tsk.closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m')
    GROUP BY usr.username ORDER BY created DESC LIMIT 20;
END
)

#echo "result_tasks_closers_top20"
result_tasks_closers_top20=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT usr.username AS user, COUNT(usr.username) AS closed
    FROM phabricator_user.user usr JOIN phabricator_maniphest.maniphest_task tsk 
    WHERE tsk.closerPHID = usr.phid
    AND FROM_UNIXTIME(tsk.closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 12 MONTH,'%Y%m')
    GROUP BY usr.username ORDER BY closed DESC LIMIT 20;
END
)

taskscreated=$(echo $result_tasks_created | sed 's/[^0-9]*//g')
tasksclosed=$(echo $result_tasks_closed | sed 's/[^0-9]*//g')
activeusers=$(echo $result_active_users | sed 's/[^0-9]*//g')
tasksauthors=$(echo $result_tasks_authors | cut -d " " -f3)
tasksclosers=$(echo $result_tasks_closers | cut -d " " -f3)

year=$(date --date='1 year ago' +%Y)

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "DRAFT: Some Phabricator and Gerrit ${year} statistics" -a "Auto-Submitted: auto-generated" ${rcpt_address}

THIS IS AN EMAIL TEMPLATE. THIS REQUIRES ADDITIONAL
MANUAL WORK FOR GERRIT BEFORE SENDING TO WIKITECH-L.

Hi everyone,

Sharing some Phabricator and Gerrit statistics from the past Gregorian calendar year ${year}. 
Big thanks to all Wikimedia technical contributors!

=== Phabricator ${year} ===

* ${taskscreated} tasks got created.
* ${tasksclosed} tasks got closed.
* ${activeusers} accounts were active in Phabricator.
* ${tasksauthors} accounts created tasks.
* ${tasksclosers} accounts closed tasks.
* The 20 accounts who created the most tasks:
${result_tasks_authors_top20}
* The 20 accounts who closed the most tasks:
${result_tasks_closers_top20}

=== Gerrit ${year} ===

* TODO changesets got created. [1]
* TODO code reviews took place. [2]
* TODO accounts created patches. [3]
* The 20 accounts who submitted the most changesets: [4]
TODO
* The 20 accounts who reviewed the most patchsets: [5]
TODO

If you find a bug in these numbers, please see
https://www.mediawiki.org/wiki/Community_metrics

Cheers!

[1] See "Gerrit 🡒 Changesets" on "Gerrit 🡒 Overview" on 
https://wikimedia.biterg.io/ after setting the time
[2] See "Total Changesets and Approvals 🡒 Approvals" on "Gerrit 🡒
Approvals" on https://wikimedia.biterg.io/ after setting the time span
[3] See "Gerrit 🡒 Changeset Submitters" on "Gerrit 🡒 Overview"
on https://wikimedia.biterg.io/ after setting the time span
[4] See "Submitters" on "Gerrit 🡒 Overview"
on https://wikimedia.biterg.io/ after setting the time span
[5] See "Approvals by Reviewer" on "Gerrit 🡒 Approvals"
on https://wikimedia.biterg.io/ after setting the time span

(via $(basename $0) on $(hostname) at $(date))
EOF
