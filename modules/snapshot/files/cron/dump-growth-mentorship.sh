#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dump-growth-mentorship.sh
#############################################################

source /usr/local/etc/dump_functions.sh

get_db_host() {
    multiversion=$1

    multiversionscript="${multiversion}/MWScript.php"
    if [ -e "$multiversionscript" ]; then
        host=$( $php -q "$multiversionscript" getReplicaServer.php --wiki="aawiki" --cluster="extension1" ) || (echo $host >& 2; host="")
    fi
    if [ -z "$host" ]; then
        echo "can't locate any x1 db server, exiting." >& 2
        exit 1
    fi
    echo $host
}

get_db_creds() {
    # note that this does not return the values but stashes them in
    # the db_user and db_pass variables.
    multiversion=$1

    multiversionscript="${multiversion}/MWScript.php"
    if [ -e "$multiversionscript" ]; then
	db_creds=$( $php "$multiversionscript" 'getConfiguration.php' '--wiki=aawiki' '--format=json' '--regex=wgDBuser|wgDBpassword')
	db_user=$( echo $db_creds | /usr/bin/jq -M -r '.wgDBuser' )
	db_pass=$( echo $db_creds | /usr/bin/jq -M -r '.wgDBpassword' )
    fi
    if [ -z "$db_user" ]; then
        echo "can't get db user name, exiting." >& 2
        exit 1
    fi
    if [ -z "$db_pass" ]; then
        echo "can't get db user password, exiting." >& 2
        exit 1
    fi
}

dump_tables() {
    wiki=$1
    tables=$2
    outputdir=$3
    mysqldump=$4
    gzip=$5
    db_user=$6
    db_pass=$7

    today=`date +%Y%m%d`
    dir="$outputdir/$today"
    mkdir -p "$dir"
    for t in $tables; do
        outputfile="${dir}/${today}-${wiki}-${t}.sql.gz"
        if [ "$dryrun" == "true" ]; then
            echo "would run:"
            echo -n "$mysqldump" -u "$db_user" -p"$db_pass" -h "$host" -P "$port" --opt --quick --skip-add-locks --skip-lock-tables "$wiki" "$t"
            echo  "| $gzip > $outputfile"
        else
            "$mysqldump" -u "$db_user" -p"$db_pass" -h "$host" -P "$port" --opt --quick --skip-add-locks --skip-lock-tables "$wiki" "$t" | "$gzip" > "$outputfile"
        fi
    done
}

configfile="${confsdir}/wikidump.conf.other"
dryrun="false"

while [ $# -gt 0 ]; do
    if [ $1 == "--config" ]; then
        configfile="$2"
        shift; shift
    elif [ $1 == "--dryrun" ]; then
        dryrun="true"
        shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

args="wiki:multiversion,dblist;tools:gzip,mysqldump,php"
results=`python3 "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

multiversion=`getsetting "$results" "wiki" "multiversion"` || exit 1
dblist=`getsetting "$results" "wiki" "dblist"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
mysqldump=`getsetting "$results" "tools" "mysqldump"` || exit 1
php=`getsetting "$results" "tools" "php"` || exit 1

for settingname in "multiversion" "gzip" "mysqldump"; do
    checkval "$settingname" "${!settingname}"
done

outputdir="${cronsdir}/growthmentorship"

host=`get_db_host "$multiversion"` || exit 1
if [[ $host == *":"* ]]; then
    IFS=: read host port <<< "$host"
else
    port="3306"
fi
get_db_creds "$multiversion" || exit 1

for wiki in $(php "$multiversion/bin/expanddblist" "growthexperiments & $dblist"); do
    dump_tables "$wiki" "growthexperiments_mentor_mentee" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
done
