#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/snapshot/dumps/fulldumps.sh
#############################################################

# This script is intended to be run out of cron, set to start
# daily, with a given date range supplied, but it will
# actually start that dump run only once during that date range.
# If there is another copy of this script already running
# or if there has been a run that completed during the date range
# then this script will simply exit.
#
# This permits the window for completion of dump runs to slip
# some if there are errors or parts that need to be rerun,
# without requiring manual intervention for the next cron run.
#
# The script runs on a dedicated snapshot host for enwiki,
# a dedicated host for wikidatawiki, and on the rest of the
# snapshot hosts for regular wikis.

usage(){
    echo "Usage: $0 startdate enddate enwiki|wikidatawiki|regular full|partial"
    echo "where enwiki, wikidatawiki, or regular is the type of wikis to be dumped"
    echo "(enwiki/wikidatawiki or small/big wikis),"
    echo "full or partial is the the type of wiki dump to be run"
    echo "(all steps including full page content history, or"
    echo "a partial dump excluding that step)"
    echo "example:"
    echo "$0 01 10 regular full"
    echo "for a run over the small and big wikis, including page"
    echo "content history, that should have started on the first"
    echo "the month and can be started up to the 10th without"
    echo "encroaching on the next dump run"
}

show (){
    if [ $dryrun -ne 0 ]; then
        echo "$1"
    fi
}

getcommandargs(){
    slots="$1"
    stagesfile="$2"
    commandargs="${repodir}/dumpscheduler.py --slots ${slots} --commands ${dumpsdir}/stages/${stagesfile} --cache ${dumpsdir}/cache/running_cache.txt --directory $repodir --formatvars STARTDATE=${startdate_yyyymmdd}"
}

maybe_do_createdirs(){
    conffile="$1"
    stagesfile="$2"
    showtype="$3"

    configfile="${confsdir}/${conffile}"
    lastrun=`$python dumpadmin.py -s lastrun --configfile $configfile`
    show "lastrun is $lastrun for ${showtype}"
    if [[ -z "$lastrun" || "$lastrun" < "$startdate_yyyymmdd" ]]; then
        getcommandargs "8" "$stagesfile"
        if [ $dryrun -ne 0 ]; then
            show "would execute ${python} ${commandargs}"
        else
            $python $commandargs >> $logfile 2>&1
        fi
    fi
}

maybe_do_dumps (){
    conffile="$1"
    stagesfile="$2"
    showtype="$3"
    slots="$4"

    configfile="${confsdir}/${conffile}"
    alldone=`$python dumpadmin.py -s alldone --configfile $configfile`
    show "alldone is ${alldone} for ${showtype}"
    if [ -z "$alldone" ]; then
        getcommandargs "$slots" "$stagesfile"
        if [ $dryrun -ne 0 ]; then
            show "would execute ${python} ${commandargs}"
        else
            $python $commandargs >> $logfile 2>&1
        fi
	return 0
    else
	return 1
    fi
}

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ]; then
    usage
    exit 1
fi

startdate="$1"
yearmonth=`/bin/date +%Y%m`
startdate_yyyymmdd="${yearmonth}${startdate}"
enddate="$2"
wikitype="$3"
dumptype="$4"
maxjobs="$5"

if [ "$wikitype" == 'none' ]; then
    # do nothing
    exit 0
fi
if [ "$6" == "dryrun" ]; then
    dryrun=1
else
    dryrun=0
fi

# don't run if there's already an instance running
# (besides me)
mypgroup=`ps --no-headers -o pgrp -p $$`
fullpids=`pgrep -f fulldumps.sh`
for pid in $fullpids; do
    pgroup=`ps --no-headers -o pgrp -p $pid`
    if [ "$pgroup" != "$mypgroup" ]; then
        show "exiting because already running"
        exit 0
    fi
done

# if dumpscheduler already running, don't start up a new one, let that run complete
pgrep dumpscheduler.py > /dev/null && exit 0
show "no dumpscheduler running so proceeding"

python="/usr/bin/python3"

source /usr/local/etc/set_dump_dirs.sh

if [ -z "$repodir" -o ! -e "$repodir" ]; then
    #fallback
    repodir="/srv/dumps"
fi
cd $repodir

today=`/bin/date +%d`
if [[ "$today" < "$startdate" || "$today" > "$enddate" ]]; then
    # skip, we're not in the run range for this dump
    show "skipping run because date out of range"
    exit 0
fi

if [ -d "/var/log/dumps" ]; then
    logdir="/var/log/dumps"
else
    logdir="/tmp"
fi
logfile="${logdir}/fulldumps_${today}_$$.log"

# clean up old logs
find "$logdir" -maxdepth 1 -name fulldumps_\* -a -mtime +90 -exec rm {} \;

# create directories for the dump run for each group of wikis
# (small, big, enwiki, wikidatawiki) as needed
case $wikitype in
    'enwiki')
        maybe_do_createdirs "wikidump.conf.dumps:en" "stages_create_enwiki" "enwiki"
        maybe_do_createdirs "wikidump.conf.dumps:bigwikis" "stages_create_bigwikis" "bigwikis"
        maybe_do_createdirs "wikidump.conf.dumps" "stages_create_smallwikis" "smallwikis"
        ;;
    'wikidatawiki')
        maybe_do_createdirs "wikidump.conf.dumps:wd" "stages_create_wikidatawiki" "wikidatawiki"
        maybe_do_createdirs "wikidump.conf.dumps:bigwikis" "stages_create_bigwikis" "bigwikis"
        maybe_do_createdirs "wikidump.conf.dumps" "stages_create_smallwikis" "smallwikis"
        ;;
    'regular')
        maybe_do_createdirs "wikidump.conf.dumps:bigwikis" "stages_create_bigwikis" "bigwikis"
        maybe_do_createdirs "wikidump.conf.dumps" "stages_create_smallwikis" "smallwikis"
        ;;
    '*')
        echo "unknown wikitype $wikitype"
        exit 1
        ;;
esac

case $dumptype in
    'full')
	enstages="stages_full_enwiki"
	wikidatastages="stages_full_wikidatawiki"
	regularstages="stages_full"
	;;
    'partial')
	enstages="stages_partial_enwiki"
	wikidatastages="stages_partial_wikidatawiki"
	regularstages="stages_partial"
	;;
    '*')
        echo "unknown dumptype $dumptype"
        exit 1
        ;;
esac

case $wikitype in
    'enwiki')
        maybe_do_dumps "wikidump.conf.dumps:en" "$enstages" "enwiki" "$maxjobs"
        # After enwiki is done, check and do some of the rest if needed
        # If not all the big wikis are done we will start a dump run covering small and big wikis
        # Only wikis without complete dumps will be updated.
        maybe_do_dumps "wikidump.conf.dumps:bigwikis" "$regularstages" "bigwikis" "$maxjobs"
	if [ $? -ne 0 ]; then
            # If we did not start a dump run above for small and big wikis, and the small wikis
            # are not done, start such a run now.  Only wikis without complete dumps will be updated.
            maybe_do_dumps "wikidump.conf.dumps" "$regularstages" "smallwikis" "$maxjobs"
        fi
        ;;
    'wikidatawiki')
        maybe_do_dumps "wikidump.conf.dumps:wd" "$wikidatastages" "wikidatawiki" "$maxjobs"
        # After wikidatawiki is done, check and do some of the rest if needed
        # If not all the big wikis are done we will start a dump run covering small and big wikis
        # Only wikis without complete dumps will be updated.
        maybe_do_dumps "wikidump.conf.dumps:bigwikis" "$regularstages" "bigwikis" "$maxjobs"
	if [ $? -ne 0 ]; then
            # If we did not start a dump run above for small and big wikis, and the small wikis
            # are not done, start such a run now.  Only wikis without complete dumps will be updated.
            maybe_do_dumps "wikidump.conf.dumps" "$regularstages" "smallwikis" "$maxjobs"
        fi
        ;;
    'regular')
        # If not all the big wikis are done we will start a dump run covering small and big wikis
        # Only wikis without complete dumps will be updated.
        maybe_do_dumps "wikidump.conf.dumps:bigwikis" "$regularstages" "bigwikis" "$maxjobs"
	if [ $? -ne 0 ]; then
            # If we did not start a dump run above for small and big wikis, and the small wikis
            # are not done, start such a run now.  Only wikis without complete dumps will be updated.
            maybe_do_dumps "wikidump.conf.dumps" "$regularstages" "smallwikis" "$maxjobs"
        fi
        ;;
    '*')
        echo "unknown wikitype $wikitype"
        exit 1
        ;;
esac
gzip $logfile 2>/dev/null
exit 0
