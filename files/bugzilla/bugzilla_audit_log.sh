#!/bin/bash
# send the Bugzilla audit log to BZ admin(s)
# per RT-4802 - dzahn 20130328

declare rcpt_address='bugzillaadmin@wikimedia.org'
declare sndr_address='4802@rt.wikimedia.org'

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

my_result=$(/usr/bin/mysql -h ${my_var[host]} -u${my_var[user]} ${my_var[name]} -p${mypass}<< END

select * from audit_log order by at_time desc;

END
)

activeusers=$(echo $my_result | cut -d " " -f3)
lastmonth=$(date --date="last month" +%Y-%m)

# the actual email
cat <<EOF | /usr/bin/mail -s "bugzilla audit log" ${rcpt_address} -- -f ${sndr_address}

Hi Bugzilla admins,

this is your automatic Bugzilla audit log mail:

$my_result

Yours sincerely,

Bugs Zilla

(via $(basename $0) on $(hostname) at $(date))
EOF

