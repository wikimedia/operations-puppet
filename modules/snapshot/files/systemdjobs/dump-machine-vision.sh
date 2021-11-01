#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/systemdjobs/dump-machine-vision.sh
#############################################################

source /usr/local/etc/dump_functions.sh

get_db_host() {
    multiversion=$1

    multiversionscript="${multiversion}/MWScript.php"
    if [ -e "$multiversionscript" ]; then
        host=$( $php -q "$multiversionscript" getReplicaServer.php --wiki="commonswiki" ) || (echo $host >& 2; host="")
    fi
    if [ -z "$host" ]; then
        echo "can't locate db server for commonswiki, exiting." >& 2
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
	db_creds=$( $php "$multiversionscript" 'getConfiguration.php' '--wiki=commonswiki' '--format=json' '--regex=wgDBuser|wgDBpassword')
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
    tables=$1
    outputdir=$2
    mysqldump=$3
    gzip=$4
    db_user=$5
    db_pass=$6

    today=`date +%Y%m%d`
    dir="$outputdir/$today"
    mkdir -p "$dir"
    for t in $tables; do
        outputfile="${dir}/${today}-${t}.gz"
        if [ "$dryrun" == "true" ]; then
            echo "would run:"
            echo -n "$mysqldump" -u "$db_user" -p"$db_pass" -h "$host" -P "$port" --opt --quick --skip-add-locks --skip-lock-tables commonswiki "$t"
            echo  "| $gzip > $outputfile"
        else
            # echo "dumping $t into $outputfile"
            "$mysqldump" -u "$db_user" -p"$db_pass" -h "$host" -P "$port" --opt --quick --skip-add-locks --skip-lock-tables commonswiki "$t" | "$gzip" > "$outputfile"
        fi
    done
}

usage() {
    echo "Usage: $0 [--config <pathtofile>] [--dryrun]" >& 2
    echo >& 2
    echo "  --config   path to configuration file for dump generation" >& 2
    echo "             (default value: ${confsdir}/wikidump.conf.other" >& 2
    echo "  --dryrun   don't run dump, show what would have been done" >& 2
    exit 1
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

args="wiki:multiversion;tools:gzip,mysqldump,php"
results=`python3 "${repodir}/getconfigvals.py" --configfile "$configfile" --args "$args"`

multiversion=`getsetting "$results" "wiki" "multiversion"` || exit 1
gzip=`getsetting "$results" "tools" "gzip"` || exit 1
mysqldump=`getsetting "$results" "tools" "mysqldump"` || exit 1
php=`getsetting "$results" "tools" "php"` || exit 1

for settingname in "multiversion" "gzip" "mysqldump"; do
    checkval "$settingname" "${!settingname}"
done

outputdir="${systemdjobsdir}/machinevision"

host=`get_db_host "$multiversion"` || exit 1
if [[ $host == *":"* ]]; then
    IFS=: read host port <<< "$host"
else
    port="3306"
fi
get_db_creds "$multiversion" || exit 1

dump_tables "machine_vision_provider" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
dump_tables "machine_vision_image" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
dump_tables "machine_vision_label" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
dump_tables "machine_vision_suggestion" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
dump_tables "machine_vision_freebase_mapping" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
dump_tables "machine_vision_safe_search" "$outputdir" "$mysqldump" "$gzip" "$db_user" "$db_pass"
