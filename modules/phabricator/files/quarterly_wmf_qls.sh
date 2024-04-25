#!/bin/bash
# Quarterly statistics of Phabricator for internal WMF QLS
# per T362804 - aklapper 20240425
# SPDX-License-Identifier: Apache-2.0
# ! this file is managed by puppet !
# ./modules/phabricator/files/quarterly_wmf_qls.sh
source /etc/phab_quarterly_wmf_qls.conf

lastquarter=$(date +"Q$(expr $(expr $(date -d '-1 month' +%m) - 1) / 3 + 1)/%Y")

#echo "result_tasks"
result_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -t -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT DISTINCT CONCAT("https://phabricator.wikimedia.org/T", t.id) AS url, t.title AS taskTitle, autr.userName AS author, ownr.userName AS assignee
    FROM phabricator_maniphest.maniphest_task t
    INNER JOIN phabricator_user.user autr ON autr.phid = t.authorPHID
    INNER JOIN phabricator_user.user ownr ON ownr.phid = t.ownerPHID
    WHERE t.status = "resolved"
    AND FROM_UNIXTIME(t.closedEpoch,'%Y%m')>=DATE_FORMAT(NOW() - INTERVAL 3 MONTH,'%Y%m')
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
         WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com'))
    AND (autr.userName != "dbarratt" AND autr.userName != "Samwilson" AND autr.userName != "Amire80" AND autr.userName != "Dreamy_Jazz" AND autr.userName != "Ladsgroup" AND autr.userName != "Tchanders" AND autr.userName != "Daimona" AND autr.userName != "Nikerabbit" AND autr.userName != "Mooeypoo" AND autr.userName != "demon" AND autr.userName != "jbond")
    AND (ownr.phid IN
            (SELECT ua.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_externalaccount ua ON ua.userPHID = u.phid WHERE ua.accountType = "mediawiki" AND ((ua.username LIKE '%(WMF)' OR ua.username LIKE '%-WMF') OR (ua.username LIKE '%(WMDE)' OR ua.username LIKE '%-WMDE')))
         OR ownr.phid IN
            (SELECT ue.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_email ue ON ue.userPHID = u.phid WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com'))
         OR (ownr.userName = "dbarratt" OR ownr.userName = "Samwilson" OR ownr.userName = "Amire80" OR ownr.userName = "Dreamy_Jazz" OR ownr.userName = "Ladsgroup" OR ownr.userName = "Tchanders" OR ownr.userName = "Daimona" OR ownr.userName = "Nikerabbit" OR ownr.userName = "Mooeypoo" OR ownr.userName = "demon" OR ownr.userName = "jbond"));
END
)

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator data for WMF QLS - ${lastquarter}" ${rcpt_address}
This is the automatic quarterly Phabricator mail for WMF QLS.

It is supposed to list Phabricator tasks reported by folks who are
not with WMF, WMDE, or contractors, and resolved in the last quarter
by folks who are with WMF, WMDE, or contractors.

WARNING: The results below are incorrect as long as staff and
contractors are allowed to use non-staff accounts and non-staff /
personal email addresses for their staff activity in Phabricator.


${result_tasks}


Yours sincerely,
Fab Rick Aytor
(via $(basename $0) on $(hostname) at $(date); see T362804)
EOF

