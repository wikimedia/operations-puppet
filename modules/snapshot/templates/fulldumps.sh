#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/fulldumps.sh.erb
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

if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: $0 startdate enddate"
    echo "example: $0 20150901 20150910 for a run that should"
    echo "have started on 20150901 and can be started up to"
    echo "20150910 without encroaching on the next dump run"    
    exit 1
fi

startdate="$1"
enddate="$2"

dumpsdir="/home/ariel/wmf/dumps/wikidata-oom/xmldumps"
cd $dumpsdir

running=`pgrep -f fulldumps.sh`
if [ ! -z "$running" ]; then
    # skip, already running
    exit 0
fi

today=`date +%Y%m%d`
if [ $today < $startdate -o $today > $enddate ]; then
    # skip, we're not in the run range for this dump
    exit 0
fi

# type will be 'regular' (= small, big) or 'huge'
for wikitype in "regular"; do

    switch $wikitype
    case $wikitype in
	"huge")
            stagesfile="stages_create_hugewikis"
	    ;;
	default)
            stagesfile="stages_create"
   	    ;;
    fi

    # determine latest "last run date" for all wikis of type
    lastrun=`python dumpadmin.py -s lastrun`
    if [ -z "$lastrun" -o "$lastrun" < "$startrundate" ]; then
        python ./dumpscheduler.py --slots 8 --commands ${dumpsdir}/stages/${stagesfile} --cache ${dumpsdir}/cache/running_cache.txt --directory $dumpsdir
        TODO="true"
    else
        alldone=`python dumpadmin.py -s alldone`
	# at least some wikis have been updated after the start date
	# if all wikis have a complete run without failures, we
	# do nothing, but otherwise we will do a full run
        if [ -z "$alldone" ]; then
            TODO="true"
	fi
    fi

    if [ ! -z "$TODO" ]; then
        for wikitype in "regular"; do
            case $wikitype in
	       "huge")
                 python ./dumpscheduler.py --slots 27 --commands ${dumpsdir}/stages/stages_normal_nocreate_hugewikis --cache ${dumpsdir}/cache/running_cache.txt --directory $dumpsdir
		 ;;
               default)
                 python ./dumpscheduler.py --slots 8 --commands ${dumpsdir}/stages/stages_normal_nocreate --cache ${dumpsdir}/cache/running_cache.txt --directory $dumpsdir
                 ;;
            esac
        done
    fi
fi
