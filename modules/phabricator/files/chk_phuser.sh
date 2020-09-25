#!/bin/bash
# Get the email address for a Phabricator user
# and check if it's verified.

phab_user=$1
source /etc/phab_community_metrics.conf

if [ -z $phab_user ];
    then echo "please provide a Phabricator username as the first argument"
    exit 1
fi

/usr/bin/mysql -u ${sql_user} -h ${sql_host} -P ${sql_port} phabricator_user -p${sql_pass} -e "select user.userName,user.id,user.phid,user_email.address,user_email.isverified from user join user_email on user_email.userPHID=user.phid where user.userName='${phab_user}';"

