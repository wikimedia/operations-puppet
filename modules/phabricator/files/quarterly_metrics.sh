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

month="$(date -d '-1 month' +%m)"
if [[ $month == 12 ]]; then
  year="$(date --date='-1 year' +'%Y')"
else
  year="$(date +'%Y')"
fi
lastquarter=$(date +"Q$(expr $(expr $month - 1) / 3 + 1)/$year")

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator quarterly statistics - ${lastquarter}" -a "Auto-Submitted: auto-generated" ${rcpt_address}

This is the automatic quarterly Phabricator statistics mail used
for https://www.mediawiki.org/wiki/Technical_Community_Newsletter

=== Phabricator and Gerrit ===

* [[mw:Phabricator|Phabricator]]: Number of tasks created in ${lastquarter}: ${taskscreated}
* Phabricator: Number of tasks closed in ${lastquarter}: ${tasksclosed}
* Phabricator: Number of different people who created tasks in ${lastquarter}: ${tasksauthors}
* Phabricator: Number of different people who closed tasks in ${lastquarter}: ${tasksclosers}
* [[mw:Gerrit|Gerrit]]: [https://wikimedia.biterg.io/goto/xxxTODOxxx X people wrote patches] ([https://wikimedia.biterg.io/goto/xxxTODOxxx X of them being volunteers]) in ${lastquarter}.


Instructions / steps how to get Gerrit statistics for that last line:

* Go to https://wikimedia.biterg.io/
* Select "Gerrit" in the top bar, then select the "Overview" subpage
* Adjust the time frame to cover the last calendar quarter:
** Select the time filter in the upper right corner
** Under "Time Range" select "Absolute"
** Set the exact start date and end date of the last calendar quarter
* Use the number of "Change Submitters" in the box called "Gerrit" as
  that is the number of all and any Gerrit contributors
* Select "Independent" in the "Organizations" pie chart to filter on
  affiliation ("Independent" organization = volunteer contributors)
* Use the number of "Change Submitters" in the box called "Gerrit" as
  that is the number of volunteer Gerrit contributors
* To create a short URL link to what you see on wikimedia.biterg.io:
** Log in via the button in the bottom left corner
*** If you do not have an account yet, see
    https://www.mediawiki.org/wiki/Community_metrics#Contact
** Select "Share" in the top bar
** Select "Permalink"
** Enable "Short URL"
** Select "Copy link"
For general info how to use wikimedia.biterg.io, see
https://www.mediawiki.org/wiki/Community_metrics


Yours sincerely,
Fab Rick Aytor

(via $(basename $0) on $(hostname) at $(date))
EOF
