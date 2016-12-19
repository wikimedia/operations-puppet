#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/dumpcentralauth.sh
#############################################################

source /usr/local/etc/set_dump_dirs.sh

usage() {
    echo "Usage: $0 --site <datacenter> [--config <pathtofile>] [--dryrun]"
    echo
    echo "  --site     codfw, eqiad, etc"
    echo "  --config   path to configuration file for dump generation"
    echo "             (default value: <%= scope.lookupvar('snapshot::dumps::dirs::confsdir') -%>/wikidump.conf"
    echo "  --dryrun   don't run dump, show what would have been done"
    exit 1
}

configfile="${confsdir}/wikidump.conf"
dryrun="false"
site=""

while [ $# -gt 0 ]; do
    if [ $1 == "--config" ]; then
        configfile="$2"
        shift; shift
    elif [ $1 == "--dryrun" ]; then
        dryrun="true"
        shift
    elif [ $1 == "--site" ]; then
        site="$2"
        shift; shift
    else
        echo "$0: Unknown option $1"
        usage
    fi
done

if [ -z "$site" ]; then
    echo "site parameter is mandatory."
    usage
fi

private=`egrep "^private=" "$configfile" | mawk -Fprivate= '{ print $2 }'`
mysqldump=`egrep "^mysqldump=" "$configfile" | mawk -Fmysqldump= '{ print $2 }'`
apachedir=`egrep "^dir=" "$configfile" | mawk -Fdir= '{ print $2 }'`
gzip=`egrep "^gzip=" "$configfile" | mawk -Fgzip= '{ print $2 }'`
if [ -z "$private" -o -z "$mysqldump" -o -z "$gzip" -o -z "$apachedir" ]; then
    echo "failed to find value of one of the following from config file $configfile:"
    echo "private, mysqldump, gzip, dir"
    echo "exiting..."
    exit 1
fi

wmfconfigdir="${apachedir}/wmf-config"
multiversionscript="${apachedir}/multiversion/MWScript.php"
dbphpfile="${wmfconfigdir}/db-${site}.php"
if [ ! -f "$dbphpfile" ]; then
    echo "failed to find $dbphpfile, exiting..."
    exit 1
fi

dbcluster=`grep centralauth "$dbphpfile" | mawk -F"'" ' { print $4 }'`
if [ ! "$dbcluster" ]; then
    echo "no db cluster available for this site, exiting..."
    exit 1
fi

wiki=`grep $dbcluster "$dbphpfile" | grep wiki | head -1 | mawk -F"'" ' { print $2 }'`
host=`php -q "$multiversionscript" getSlaveServer.php --wiki="$wiki" --group=dump`
if [ -z "$dbcluster" -o -z "$wiki" -o -z "$host" ]; then
    echo "can't locate db server for centralauth, exiting."
    exit 1
fi

wikiadmin=`echo 'echo $wgDBadminuser;' | php "$multiversionscript" eval.php $wiki`
wikipass=`echo 'echo $wgDBadminpassword;' | php "$multiversionscript" eval.php $wiki`
if [ -z "$wikiadmin" -o -z "$wikipass" ]; then
    echo "can't get db user name and password, exiting."
    exit 1
fi

tables="global_group_permissions global_group_restrictions global_user_groups globalblocks globalnames globaluser localnames localuser migrateuser_medium spoofuser wikiset"
today=`date +%Y%m%d`
dir="$private/centralauth/$today"
mkdir -p "$dir"
for t in $tables; do
    outputfile="$dir/centralauth-$today-$t.gz"
    if [ "$dryrun" == "true" ]; then
        echo "would run:"
        echo -n "$mysqldump" -u "$wikiadmin" -p"$wikipass" -h "$host" --opt --quick --skip-add-locks --skip-lock-tables centralauth "$t"
        echo  "| $gzip > $outputfile"
    else
        # echo "dumping $t into $outputfile"
        "$mysqldump" -u "$wikiadmin" -p"$wikipass" -h "$host" --opt --quick --skip-add-locks --skip-lock-tables centralauth "$t" | "$gzip" > "$outputfile"
    fi
done
