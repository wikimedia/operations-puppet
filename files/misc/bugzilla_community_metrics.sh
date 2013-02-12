#!/bin/bash
# send the number of active users on Bugzilla
# in the last month to "community metrics" team
# per RT-3962 - dzahn 20121219

declare rcpt_address='communitymetrics@wikimedia.org'
declare sndr_address='3962@rt.wikimedia.org'

# reads db user/pass/host from bugzilla config
declare bugzilla_path='/srv/org/wikimedia/bugzilla'
declare -a config_var=(host name user pass)
declare -A my_var
declare script_user='www-data'

define(){ IFS='\n' read -r -d '' ${1} || true; }

for mv in "${config_var[@]}"; do
	my_var[$mv]=$(grep db_${mv} ${bugzilla_path}/localconfig | cut -d\' -f2 | sed 's/;/\\\;/g')
done

# fix if there is a ; in the pass itself
mypass=$(echo ${my_var[pass]} | sed 's/\\//g')

my_result=$(MYSQL_PWD=${mypass} /usr/bin/mysql -h ${my_var[host]} -u${my_var[user]} ${my_var[name]} << END

select
	count(distinct userid)
from
(
	select
		ba.who as userid,
		ba.bug_when as action_date
	from bugs_activity ba
	where
		date_format(ba.bug_when,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m') and
		ba.fieldid in (2,4,5,6,7,8,9,10,11,12,13,14,15,16,18,19,30,35,36,37,38,40,41,42,47,55,56,57,58)
	group by action_date,userid
	union all
		select
			b.reporter,
			b.creation_ts
		from bugs b
		where
			date_format(b.creation_ts,'%Y%m')=date_format(NOW() - INTERVAL 1 MONTH,'%Y%m')
) as filtered_actions;

END
)

activeusers=$(echo $my_result | cut -d " " -f3)
lastmonth=$(date --date="last month" +%Y-%m)

# the actual email
cat <<EOF | /usr/bin/mail -s "bugzilla stats - ${lastmonth}" ${rcpt_address} -- -f ${sndr_address}

Hi Community Metrics team,

this is your automatic monthly Bugzilla statistics mail.

The number of active users in Bugzilla in the last month (${lastmonth}) was: ${activeusers}

Yours sincerely,

Bugs Zilla

(via $(basename $0) on $(hostname) at $(date))
EOF

