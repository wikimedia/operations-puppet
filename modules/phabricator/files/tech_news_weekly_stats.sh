#!/bin/bash
# Weekly statistics of Phabricator for Tech News
# https://meta.wikimedia.org/wiki/Tech/News
# per T368460 - aklapper 20240626
# SPDX-License-Identifier: Apache-2.0
# ! this file is managed by puppet !
# ./modules/phabricator/files/tech_news_weekly_stats.sh
source /etc/tech_news_weekly_stats.conf
timestamp=$(date)
#echo "result_tasks"
result_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -t -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT DISTINCT CONCAT("https://phabricator.wikimedia.org/T", t.id) AS url, t.title AS taskTitle, autr.userName AS author, ownr.userName AS assignee
    FROM phabricator_maniphest.maniphest_task t
    INNER JOIN phabricator_user.user autr ON autr.phid = t.authorPHID
    INNER JOIN phabricator_user.user ownr ON ownr.phid = t.ownerPHID
    WHERE t.status = "resolved"
    AND FROM_UNIXTIME(t.closedEpoch)>=(NOW() - INTERVAL 168 HOUR)
    AND autr.phid NOT IN
        (SELECT ua.userPHID
         FROM phabricator_user.user u
         INNER JOIN phabricator_user.user_externalaccount ua
         ON ua.userPHID = u.phid
         WHERE ua.accountType = "mediawiki"
         AND ((ua.username LIKE '%(WMF)' OR ua.username LIKE '%-WMF')
         OR (ua.username LIKE '%(WMDE)' OR ua.username LIKE '%-WMDE')))
    AND autr.phid NOT IN
        (SELECT ue.userPHID
         FROM phabricator_user.user u
         INNER JOIN phabricator_user.user_email ue
         ON ue.userPHID = u.phid
         WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com' OR ue.address LIKE '%@thisdot.co'))
    AND (ownr.phid IN
            (SELECT ua.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_externalaccount ua ON ua.userPHID = u.phid WHERE ua.accountType = "mediawiki" AND ((ua.username LIKE '%(WMF)' OR ua.username LIKE '%-WMF') OR (ua.username LIKE '%(WMDE)' OR ua.username LIKE '%-WMDE')))
         OR ownr.phid IN
            (SELECT ue.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_email ue ON ue.userPHID = u.phid WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com' OR ue.address LIKE '%@thisdot.co')));
END
)
# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Weekly Phabricator data for Tech News - ${timestamp}" ${rcpt_address}
This is the automatic weekly Phabricator mail for Tech News.

It is supposed to list Phabricator tasks reported by folks who are
not with WMF, WMDE, or contractors, and resolved in the last quarter
by folks who are with WMF, WMDE, or contractors.

IMPORTANT:
The results below are incorrect as long as staff and contractors
are allowed to use non-staff accounts and non-staff/personal email
addresses and accounts for their staff activity in Phabricator.

Thus results and numbers MUST be manually reviewed and corrected:

${result_tasks}

Yours sincerely,
Fab Rick Aytor
(via $(basename $0) on $(hostname) at $(date); see T368460)
EOF
