#!/bin/bash
# send Phabricator 2fa account coverage (T299403) to aklapper@wikimedia.org
# ! this file is managed by puppet !
# ./modules/phabricator/files/mfa_check.sh

source /etc/phab_mfa_check.conf

#echo "result_admins_and_security"
result_admins_and_security=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT DISTINCT(CONCAT("https://phabricator.wikimedia.org/p/", u.userName)) AS user
  FROM phabricator_user.user u
  JOIN phabricator_project.edge e
  ON u.phid = e.dst
  WHERE ((e.src = "PHID-PROJ-koo4qqdng27q7r65x3cw"
    AND (e.type=14 OR e.type=60))
    OR u.isAdmin = 1)
  AND u.isDisabled = 0
  AND u.isSystemAgent = 0
  AND u.phid NOT IN
    (SELECT mfa.userPHID FROM phabricator_auth.auth_factorconfig mfa);
END
)

#echo "result_acl_stewards"
result_acl_stewards=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT DISTINCT(CONCAT("https://phabricator.wikimedia.org/p/", u.userName)) AS user
  FROM phabricator_user.user u
  JOIN phabricator_project.edge e
  ON u.phid = e.dst
  WHERE (e.src = "PHID-PROJ-py76uxfk5h7eem3wljmf"
    AND (e.type=14 OR e.type=60))
  AND u.isDisabled = 0
  AND u.phid NOT IN
    (SELECT mfa.userPHID FROM phabricator_auth.auth_factorconfig mfa);
END
)

#echo "result_wmf_nda"
result_wmf_nda=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT DISTINCT(CONCAT("https://phabricator.wikimedia.org/p/", u.userName)) AS user
  FROM phabricator_user.user u
  JOIN phabricator_project.edge e
  ON u.phid = e.dst
  WHERE (e.src = "PHID-PROJ-ibxm3v6ithf3jpqpqhl7"
    AND (e.type=14 OR e.type=60))
  AND u.isDisabled = 0
  AND u.phid NOT IN
    (SELECT mfa.userPHID FROM phabricator_auth.auth_factorconfig mfa);
END
)
# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator 2FA account check" -a "Auto-Submitted: auto-generated" ${rcpt_address}

Hi Phabricator admin,

This is your automatic weekly Phabricator mail
listing elevated accounts and their 2FA status.
  * https://phabricator.wikimedia.org/people/query/advanced/

NON-BOT PHAB ADMINS AND SECURITY:
  * Security: https://phabricator.wikimedia.org/project/members/30/
  * Admins: https://phabricator.wikimedia.org/people/query/WETApwetxsAM/#R

${result_admins_and_security}

For an account listed, file a ticket and assign it to the user account:
https://phabricator.wikimedia.org/maniphest/task/edit/form/73/?title=Enable%202FA%20for%20your%20Phabricator%20account%20with%20access%20to%20Security%20tasks%20or%20risk%20losing%20access&description=Hi%2C%20currently%20your%20Phab%20account%20does%20not%20have%202FA%20enabled.%20As%20you%20have%20access%20to%20security%20issues%20%5Bwhich%20requires%202FA%5D(https%3A%2F%2Fwww.mediawiki.org%2Fwiki%2FWikimedia_Security_Team%2FPolicy%2FAccess_To_Security_Issues)%2C%20could%20you%20please%20enable%20it%20at%20https%3A%2F%2Fphabricator.wikimedia.org%2Fsettings%2Fpanel%2Fmultifactor%2F%20and%20then%20set%20the%20status%20of%20this%20task%20to%20%60resolved%60%3F%20Thanks%20a%20lot!&projects=phabricator%2Csecurity&priority=high

ACL*STEWARDS MEMBERS:
  * https://phabricator.wikimedia.org/project/members/2849/

${result_acl_stewards}

WMF-NDA MEMBERS:
  * https://phabricator.wikimedia.org/project/members/61/

${result_wmf_nda}

Yours sincerely,
Fab Rick Aytor

(via $(basename $0) on $(hostname) at $(date))
EOF
