#!/bin/bash
# Quarterly statistics of Phabricator for internal WMF QLS
# per T362804 - aklapper 20240425
# SPDX-License-Identifier: Apache-2.0
# ! this file is managed by puppet !
# ./modules/phabricator/files/quarterly_wmf_qls.sh
source /etc/phab_quarterly_wmf_qls.conf

lastquarterint=$(expr $(expr $(date -d '-1 month' +%m) - 1) / 3 + 1)

if (( $lastquarterint % 4 == 1 ))
then lastquarterintfy=3
elif (( $lastquarterint % 4 == 2 ))
then lastquarterintfy=4
elif (( $lastquarterint % 4 == 3 ))
then lastquarterintfy=1
elif (( $lastquarterint % 4 == 0 ))
then lastquarterintfy=2
fi

lastquarterstr=$(date +"Q$lastquarterint/%Y (Q$lastquarterintfy in FY)")

#echo "result_tasks"
result_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -t -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT DISTINCT t.phid AS phid, autr.userName AS author, t.status AS status, ownr.userName AS owner, FROM_UNIXTIME(t.closedEpoch, '%Y-%m-%d') AS closedDate, clsr.userName AS closer, t.priority AS priority, t.subtype AS subtype, CONCAT("https://phabricator.wikimedia.org/T", t.id) AS url, t.title AS taskTitle, FROM_UNIXTIME(t.dateCreated, '%Y-%m-%d') AS createdDate, ROUND((t.closedEpoch - t.dateCreated) / 86400) AS daysBetween
    FROM phabricator_maniphest.maniphest_task t
    INNER JOIN phabricator_user.user autr ON autr.phid = t.authorPHID
    INNER JOIN phabricator_user.user ownr ON ownr.phid = t.ownerPHID
    INNER JOIN phabricator_user.user clsr ON clsr.phid = t.closerPHID
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
    AND (ownr.phid IN
            (SELECT ua.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_externalaccount ua ON ua.userPHID = u.phid WHERE ua.accountType = "mediawiki" AND ((ua.username LIKE '%(WMF)' OR ua.username LIKE '%-WMF') OR (ua.username LIKE '%(WMDE)' OR ua.username LIKE '%-WMDE')))
         OR ownr.phid IN
            (SELECT ue.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_email ue ON ue.userPHID = u.phid WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com')));
END
)

#echo "result_projects"
result_projects=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -t -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT t.id AS taskId, t.phid AS phid, p.name AS projectTag
    FROM phabricator_maniphest.maniphest_task t
    INNER JOIN phabricator_maniphest.edge e ON t.phid = e.src
    INNER JOIN phabricator_project.project p ON e.dst = p.phid
    WHERE e.type = 41
    AND t.phid IN
        (SELECT DISTINCT t.phid
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
         AND (ownr.phid IN
                 (SELECT ua.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_externalaccount ua ON ua.userPHID = u.phid WHERE ua.accountType = "mediawiki" AND ((ua.username LIKE '%(WMF)' OR ua.username LIKE '%-WMF') OR (ua.username LIKE '%(WMDE)' OR ua.username LIKE '%-WMDE')))
              OR ownr.phid IN
                 (SELECT ue.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_email ue ON ue.userPHID = u.phid WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com')))) 
    ORDER BY t.id;
END
)

#echo "result_subscribers"
result_subscribers=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -t -h $sql_host -P $sql_port -u $sql_user phabricator_maniphest << END
SELECT t.id AS taskId, t.phid AS phid, u.userName AS subscriber
    FROM phabricator_maniphest.maniphest_task t
    INNER JOIN phabricator_maniphest.edge e ON t.phid = e.src
    INNER JOIN phabricator_user.user u ON e.dst = u.phid
    WHERE e.type = 21 
    AND t.phid IN
        (SELECT DISTINCT t.phid
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
         AND (ownr.phid IN
                 (SELECT ua.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_externalaccount ua ON ua.userPHID = u.phid WHERE ua.accountType = "mediawiki" AND ((ua.username LIKE '%(WMF)' OR ua.username LIKE '%-WMF') OR (ua.username LIKE '%(WMDE)' OR ua.username LIKE '%-WMDE')))
              OR ownr.phid IN
                 (SELECT ue.userPHID FROM phabricator_user.user u INNER JOIN phabricator_user.user_email ue ON ue.userPHID = u.phid WHERE (ue.address LIKE '%@wikimedia.org' OR ue.address LIKE '%@wikimedia.de' OR ue.address LIKE '%@speedandfunction.com')))) 
    AND u.isDisabled != 1 
    ORDER BY t.id;
END
)

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator data for WMF QLS - ${lastquarterstr}" ${rcpt_address}
This is the automatic quarterly Phabricator mail for WMF QLS.

It is supposed to list Phabricator tasks reported by folks who are
not with WMF, WMDE, or contractors, and resolved in the last quarter
by folks who are with WMF, WMDE, or contractors.

WARNING: Results and numbers of tasks below are incorrect as staff
and contractors can use non-staff accounts and non-staff / personal
email addresses for their staff activity. There is no way to
reliably identify staff or contractors due to lack of WMF policies.


=== TASKS ===

Meaning of priority values:
100=Unbreak Now!, 90=Needs Triage, 80=High, 50=Medium, 25=Low, 10=Lowest.

${result_tasks}


=== PROJECT TAGS ===

${result_projects}


=== NON-DISABLED SUBSCRIBERS ===

${result_subscribers}


Yours sincerely,
Fab Rick Aytor
(via $(basename $0) on $(hostname) at $(date); see T362804, T370947)
EOF

