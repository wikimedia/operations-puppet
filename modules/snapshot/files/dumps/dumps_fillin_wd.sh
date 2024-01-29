#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

#############################################################
# This file is maintained by puppet!
# modules/snapshot/dumps/dumps_fillin_wd.sh
#############################################################

# This script is intended to be run as a periodic job, set to start
# daily, with a given date range supplied, but it will
# actually start that dump run only once during that date range.
# If there is another copy of this script already running
# or if there has been a run that completed during the date range
# then this script will simply exit.
#
# This permits the window for completion of dump runs to slip
# some if there are errors or parts that need to be rerun,
# without requiring manual intervention for the next timer/service run.
#
# The script should run on a dedicated snapshot dumps fillin host for wikidatawiki.

# It writes information to a dedicated status file in the dumps run
# temp directory for the specific wiki and date, i.e.
# (start of path...)/temp/w/wikidatawiki/wikidatawiki-fixups-YYYYMMDD-status.txt
# No other dump job scripts use this status file.
#
# It logs information about the run to a dedicated log file in the dumps run
# private directory for the specific wiki and date, i.w.
# (start of path...)/private/wikidatawiki/YYYYMMDD/dumplog_fillin.pid
# No other dump job scripts write to these log files.

MAXFAILS=5

usage(){
    cat<<EOF
Usage: $0 --wiki wikidbname --startday daynum --endday daynum --numjobs num
          --jobinfo partstart,partend --config configfilepath [ --dryrun ] [ --verbose ]

This script should be run on a worker host to generate page content
history files for ${WIKI} for specified output file parts
during the full dump run for that wiki. It should be started shortly
after the dump run for the wiki reaches the pages meta history
job and has started to generate one of them. This ensures that the
needed temporary stub files are already available.

Like the fullrun script, this script can be run twice a day, over
a range of dates, to be sure that it completes in case of error or
interruption.

Example:
 /bin/bash $0 --wiki wikidatawiki --startday 05 --endday 15 --jobinfo 21:25 --numjobs 27
    --config /etc/dumps/confs/wikidump.conf.dumps:wd
to execute each day of the month from the 5th through the 15th, covering parts 21 through 25 of the full history
of wikidata, using the production dumps config and 27 processes running in parallel

To check what commands this script would run, add the argument "--dryrun"
To emit more messages about what this script is doing than usual, add the argument "--verbose"
EOF
    exit 1
}

set_defaults() {
    CONFIGFILE=""
    WIKI=""
    PARTRANGE=""
    STARTDAY=""
    ENDDAY=""
    NUMJOBS=""
    DRYRUN=0
    VERBOSE=1
}

process_opts () {
    while [ $# -gt 0 ]; do
	if [ "$1" == "--config" ]; then
		CONFIGFILE="$2"
		shift; shift;
	elif [ "$1" == "--wiki" ]; then
		WIKI="$2"
		shift; shift
	elif [ "$1" == "--jobinfo" ]; then
		PARTRANGE="$2"
		shift; shift
	elif [ "$1" == "--startday" ]; then
		STARTDAY="$2"
		shift; shift
	elif [ "$1" == "--endday" ]; then
		ENDDAY="$2"
		shift; shift
	elif [ "$1" == "--numjobs" ]; then
		NUMJOBS="$2"
		shift; shift
	elif [ "$1" == "--dryrun" ]; then
		DRYRUN=1
		shift
	elif [ "$1" == "--verbose" ]; then
		VERBOSE=1
		shift
	else
		echo "$0: Unknown option $1"
		usage
	fi
    done
}

check_opts() {
    if [ -z "$WIKI" ] || [ -z "$PARTRANGE" ] || [ -z "$STARTDAY" ] || [ -z "$ENDDAY" ] || [ -z "$NUMJOBS" ] || [ -z "$CONFIGFILE" ]; then
        logit "$0: Mandatory options 'wiki', 'jobinfo', 'startday', 'endday', 'numjobs' and 'config' must be specified" ERR
        usage
    fi
    if ! [[ "$PARTRANGE" =~ ^([0-9,]+)$ ]]; then
        logit "$0: Bad format $PARTRANGE for 'jobinfo' option" ERR
	usage
    fi
}

# expects first arg to be a string to be echoed if verbose was set,
# also written to the log
# if writing to the log is not desired, pass second arg "INFO"
logit() {
    lognow=$( /usr/bin/date -u +'%Y%m%d%H%M%S' )
    displayed=0
    if [ -n "$logfile" ] && [ "$2" != "INFO" ]; then
	echo "${lognow} ${1}" >> "$logfile"
    fi
    # display all errors on console
    if [ -z "$logfile" ] && [ "$2" == "ERR" ]; then
	echo "${lognow} ${1}"
	displayed=1
    fi
    # don't double display things in verbose mode
    if [[ $VERBOSE -ne 0 ]] && [[ $displayed -eq 0 ]]; then
	echo "${lognow} ${1}"
    fi
}

# check if this script is already running via some other process
# returns 1 if true, 0 otherwise
not_already_running() {
    mypgroup=$( /usr/bin/ps --no-headers -o pgrp -p $$ )
    fullpids=$( /usr/bin/pgrep -f "$0" )
    for pid in $fullpids; do
	pgroup=$( /usr/bin/ps --no-headers -o pgrp -p "$pid" )
	if [ "$pgroup" != "$mypgroup" ]; then
	    logit "Script already running, exiting" WARN
	    return 1
	fi
    done
    return 0
}

# given part numbers for history files to run, each part must be split into tiny jobs,
# each of which don't take more than a few hours to run; the start and end page numbers
# for each output file for these jobs are written in a json file by the main dump process.
# we read the json file for the ongoing dump, extract that information, and turn it
# into a string
# expects part numbers passed in (example: some numbers in the range 1 - 27)
# format: "num", "nextnum", "anothernum", ... , "lastnum"
# returns a string of part numbers plus page ranges
# format: partnum:startpage:endpage partnum:startpage:endpage ... partnum:startpage:endpage
# sets: rangesforparts
get_pageranges(){
    parts_todo="$1"
    pagerangefile="${xmldumpspublicdir}/${WIKI}/${startdate_yyyymmdd}/pagerangeinfo.json"
    if [ ! -f "$pagerangefile" ]; then
	logit "missing pagerange file ${xmldumpspublicdir}/${WIKI}/${startdate_yyyymmdd}/pagerangeinfo.json" ERR
	return 1
    fi
    ready=$( /usr/bin/grep -c 'meta-history' "$pagerangefile" )
    if [[ $ready -eq 0 ]]; then
	# this probably means that the stubs are being written still but page range info is not there yet for full content dumps
	# we can try again on the next run
	logit "file ${xmldumpspublicdir}/${WIKI}/${startdate_yyyymmdd}/pagerangeinfo.json missing meta-history info" WARN
	return 1
    fi

    # json file entry format:
    # {"articles": [["1", "441397", "1"], ["441398", "1114931", "2"], ...]]}
    # where there can be multiple tuples per part.
    # rangesforparts=$( cat pagerangeinfo.json  | jq -r '."meta-history"[] |  map(.) | {start: .[0], end:.[1], part:.[2]} | select(.part == "27") | "\(.part):\(.start):\(.end)"' )
    rangesforparts=$( /usr/bin/cat "$pagerangefile" | /usr/bin/jq -r '."meta-history"[] |  map(.) | {start: .[0], end:.[1], part:.[2]} | select(.part == ( '"$parts_todo"' )) | "\(.part):\(.start):\(.end)"' )
}

# given a string, a separator and the number of the element you want starting from zero
# split the string on the separator and return that element
# example:  get_nth_element 20,22,25 , 0
# if the array is shorter than the element, the empty string is returned
get_nth_element() {
    IFS_SAVE="$IFS"
    IFS="$2"
    temp_array=( $1 )
    IFS="$IFS_SAVE"
    if [[ ${#temp_array[@]} -lt $3 ]]; then
	echo ""
    else
	echo "${temp_array[$3]}"
    fi
}

# pass in a partnum
# return a list of the stub files for that part, if any
get_stubs_for_part() {
    part_todo="$1"
    ls "${dumpstempdir}/${WIKIFIRSTLETTER}/${WIKI}/${WIKI}-${startdate_yyyymmdd}-stub-meta-history${part_todo}.xml-p"*.gz 2>/dev/null
}

# get the list  of stub input files which correspond to the output files that can be produced
# sets: stubs (array)
get_stubs() {
    part_start=$( get_nth_element "$1" "," "0" )
    part_end=$( get_nth_element "$1" "," "1" )
    if [ -z "$part_end" ]; then
	part_end=$part_start
    fi
    partlist=$( /usr/bin/seq "$part_start" "$part_end" )
    stubs=()
    for part in $partlist; do
	stubs[$part]=$( get_stubs_for_part "$part" )
    done
}

# check that we have stub files for every part in the range
# returns 0 if true, 1 otherwise
check_all_stubs_present() {
    part_start=$( get_nth_element "$1" "," "0" )
    part_end=$( get_nth_element "$1" "," "1" )
    if [ -z "$part_end" ]; then
	part_end=$part_start
    fi
    partlist=$( /usr/bin/seq "$part_start" "$part_end" )
    for part in $partlist; do
	if [ -z "${stubs[$part]}" ]; then
	    return 1
	fi
    done
    return 0
}

# find the stub file that goes with this page range;
# convert that to a page meta history file name in the right place;
# return that if it exists, if not, return empty string
#
# there should be only one stub file that corresponds. if not, other things will be
# really broken and we leave it to other systems to handle those issues
#
# file name format: wikidatawiki-20230901-pages-meta-history23.xml-p56624755p56631400.bz2
get_outputpath() {
    jobinfo=$1
    part_wanted=$( get_nth_element "$jobinfo" ":" "0" )
    page_start_wanted=$( get_nth_element "$jobinfo" ":" "1" )
    page_end_wanted=$( get_nth_element "$jobinfo" ":" "2" )

    for filepath in ${stubs[$part_wanted]}; do

	# stub filename format: wikidatawiki-20240201-stub-meta-history4.xml-p763848p770656.gz
	stub_basename=$( basename -s .gz "$filepath" )
	fname_prefix="${WIKI}-${startdate_yyyymmdd}-stub-meta-history${part_wanted}.xml-p"
	stub_pages=${stub_basename#"$fname_prefix"}

        # we now have 763848p770656 so need to split that, then see if this page start is in our range
	stub_page_start=$( get_nth_element "$stub_pages" "p" "0" )
	stub_page_end=$( get_nth_element "$stub_pages" "p" "1" )
	if [[ $stub_page_start -ge $page_start_wanted ]] && [[ stub_page_start -le $page_end_wanted ]]; then

	    # assemble the corresponding history content file path and check existence
	    basedir="${xmldumpspublicdir}/${WIKI}/${startdate_yyyymmdd}/"
	    historyfilename="${WIKI}-${startdate_yyyymmdd}-pages-meta-history${part_wanted}.xml-p${stub_page_start}p${stub_page_end}.bz2"
	    if [ -f "${basedir}/${historyfilename}" ]; then
		echo "${basedir}/${historyfilename}"
		return
	    else
		# stub file found and has no output file yet
		echo ""
	    fi
	fi
    done
    # shouldn't happen but still: no stub file for this partrange at all
    echo ""
}


# given partstart:partend  like e.g.  20,27  or perhaps just a single number like  22
# generate a string of part numbers formatted e.g. like "1", "2", "3", "4", "5"
# sets: PARTS
get_parts() {
    if [ -z "$1" ]; then
        echo "empty part start/end specified"
        return 1
    fi
    # single numeric arg
    if [[ "$1" =~ ^([0-9]+)$ ]]; then
	part_start="$1"
	part_end="$1"
    else
	part_start=$( get_nth_element "$1" "," "0" )
	part_end=$( get_nth_element "$1" "," "1" )
    fi

    # format wanted:   "1", "2", "3", "4", "5"
    PARTS='"'$( /usr/bin/seq -s '", "' "$part_start" "$part_end" )'"'
}

# given part startnum,endnum (or perhaps startnum by itself)
# and then return a string of part numbers plus start and end pages of jobs to be run,
# formatted like e.g. partnum:startpage:endpage,partnum:startpage:endpage...
# where each partnum has one entry with the with the page start and end covering the
# entire part; the script we invoke will only generate files for the part that
# are missing, so we can pass it the full range with no worries
# sets: jobinfo_arg
get_jobinfo_arg() {
    logit "Doing parts $PARTS" INFO
    ok=0
    failures=0
    while [[ $ok -eq 0 ]] && [[ $failures -le $MAXFAILS ]]; do
	get_pageranges "$PARTS"
	if [[ $? -eq 0 ]]; then
	    ok=1
	else
            failures=$(($failures+1))
	    # wait 30 minutes, try again; the regular dumps worker may not have gotten
	    # to this step yet.
	    logit "sleeping 30 minutes after failure to get page ranges" INFO
	    sleep 1800
	fi
    done
    if [[ $ok -eq 0 ]]; then
	# this would be the fault of this script running too early in the dumps run,
	# when the regular dumps worker has not done the prerequisite work.
	# in the normal circumstance, not an error as such.
	logit "($$) Could not get page ranges too many times, giving up" WARN
        return 1
    fi

    # turn the results into a nice argument of the right format for the textpass script
    part_start=$( get_nth_element "$1" "," "0" )
    part_end=$( get_nth_element "$1" "," "1" )
    if [ -z "$part_end" ]; then
	part_end=$part_start
    fi
    partlist=$( /usr/bin/seq "$part_start" "$part_end" )
    jobinfo_arg=""
    for part_todo in $partlist; do

	startpages=$( /usr/bin/cat "$pagerangefile" | /usr/bin/jq -r '."meta-history"[] |  map(.) | {start: .[0], end:.[1], part:.[2]} | select(.part == ( "'"$part_todo"'" )) | "\(.start)"' )
	endpages=$( /usr/bin/cat "$pagerangefile" | /usr/bin/jq -r '."meta-history"[] |  map(.) | {start: .[0], end:.[1], part:.[2]} | select(.part == ( "'"$part_todo"'" )) | "\(.end)"' )

	startpages_array=($startpages)
	endpages_array=($endpages)

	IFS_SAVE="$IFS"
	IFS=$'\n' startpages_sorted=( $( /usr/bin/sort -n <<< "${startpages_array[*]}" ) )
	IFS=$'\n' endpages_sorted=( $( /usr/bin/sort -n <<< "${endpages_array[*]}" ) )
	IFS="$IFS_SAVE"

	jobinfo="${part_todo}:${startpages_sorted[0]}:${endpages_sorted[-1]}"
	jobinfo_arg="${jobinfo_arg} $jobinfo"
    done

    # remove leading space
    jobinfo_arg="${jobinfo_arg# }"
    # get comma sep list of partnum:startpage:endpage,partnum:startpage:endpage...
    # shellcheck disable=SC2086
    jobinfo_arg=$( echo ${jobinfo_arg// /,} )
}

# check if a run has marked these as done in status file
# returns 0 if done, 1 if not
check_if_status_done() {
    if [ -f "$statusfile" ]; then
	# empty file or with no whitespace (without Done) will dtrt here.
	status=$( cat "$statusfile" | { read -r first rest ; echo "$first" ; } )
	if [ "$status" == "Done" ]; then
	    return 0
	fi
    fi
    return 1
}

# check if all the expected files have been written and are not truncated
# returns 0 if true, 1 otherwise
check_if_fillin_completed() {
    get_pageranges "$PARTS"

    # should never happen but...
    if [[ $? -ne 0 ]]; then
	logit "($$) Could not get page ranges too many times checking if fillin completed, giving up" ERR
        return 1
    fi

    if [[ $DRYRUN -ne 0 ]]; then
	return 0
    fi

    for jobinfo in $rangesforparts; do
	outputpath=$( get_outputpath "$jobinfo" )
	if [ -z "$outputpath" ]; then
	    echo "missing output file for $jobinfo"
	    return 1
	fi
	/usr/local/bin/checkforbz2footer "$outputpath"
	if [[ $? -ne 0 ]]; then
	    logit "($$) Incomplete file ${outputpath} found." ERR
	    return 1
	fi
    done

    return 0
}

# run the script that actually does the jobs, in batches
# that script will write each output file into a temp location, then move into
# place once complete; it will not write out md5sums for the output files
# or do other ancillary processing; that is the job of the main dumps
# run process, which will do that for all output files once it determines
# that the job is successful.
# returns 0 if everything completes successfully, 1 otherwise
do_fillin() {
    jobinfo_arg="$1"
    done=0

    check_if_status_done
    if [[ $? -eq 0 ]]; then
	# done earlier by someone else? in any case, nothing left for us.
	logit "This dump run is already complete, skipping." INFO
	return $done
    fi

    FAILED=0
    now=$( date -u +'%Y%m%d%H%M%S' )
    command="${repodir}/fixup_scripts/do_dumptextpass_jobs.sh"
    command_args="--wiki wikidatawiki --config $CONFIGFILE --date $startdate_yyyymmdd --skiplock --numjobs $NUMJOBS --jobinfo $jobinfo_arg"
    command_args_array=($command_args)
    if [[ $DRYRUN -ne 0 || $VERBOSE -ne 0 ]]; then
	echo "echo Started ($$) $now > $statusfile"
        echo "/bin/bash $command ${command_args_array[*]} >> $logfile 2>&1"
    fi
    if [[ $DRYRUN -eq 0 ]]; then
        echo "Started ($$) $now" > "$statusfile"
	# shellcheck disable=SC2086
        /bin/bash $command "${command_args_array[@]}" >> "$logfile"  2>&1
	if [[ $? -ne 0 ]]; then
	    FAILED=1
	fi
    fi
    if [[ $FAILED -ne 0 ]]; then
	logit  "($$) Dump fillin for $WIKI failed, command failed." ERR
	done=1
    else
        check_if_fillin_completed
	if [[ $? -ne 0 ]]; then
	    logit " ($$) Dump fillin for $WIKI failed, some files were not written. $$" ERR
	    done=1
	else
            if [[ $DRYRUN -ne 0 ]]; then
	        echo "echo $now ($$) Dump fillin for $WIKI complete. >> $logfile"
	        echo "echo Done ($$) $now > $statusfile"
            else
		logit "($$) Dump fillin for $WIKI complete." INFO
	        echo "Done ($$) now" > "$statusfile"
            fi
	fi
    fi
    if [[ $DRYRUN -ne 0 ]]; then
        echo /usr/bin/gzip "$logfile" ' 2>/dev/null'
    else
        /usr/bin/gzip "$logfile" 2>/dev/null
    fi
    return $done
}

################
# entry point
#
set_defaults
process_opts "$@"
check_opts || exit 1

yearmonth=`/bin/date +%Y%m`
# THIS IS A HORRIBLE HACK. But this script is supposed to be short-lived. So yes we hardcode in the
# real run as starting on the first of the month. Period.
startdate_yyyymmdd="${yearmonth}01"

today=`/bin/date +%d`
if [[ "$today" < "$STARTDAY" || "$today" > "$ENDDAY" ]]; then
    # skip, we're not in the run range for this dump
    logit "Today is not in date range specified, exiting" INFO
    exit 0
fi

not_already_running || exit 0

# thser vars will be set via the sourced shell script below
xmldumpspublicdir=""
confsdir=""
dumpstempdir=""

setup_dirs="/usr/local/etc/set_dump_dirs.sh"
# shellcheck disable=SC1090
source "$setup_dirs"

if [ -z "$xmldumpspublicdir" ] || [ -z "$confsdir" ] || [ -z "$dumpstempdir" ]; then
    echo "$setup_dirs missing some settings, please fix"
    exit 1
fi

if [ -z "$repodir" ] || [ ! -e "$repodir" ]; then
    #fallback
    repodir="/srv/dumps"
fi
cd $repodir || ( echo "$repodir cd failed, giving up" ; exit 1 )

# ANOTHER HORRIBLE HACK
privatedir="${xmldumpspublicdir}/../private"

# the regular dump worker ought to have made this directory, but for testing purposes...
mkdir -p "${privatedir}/${WIKI}/${startdate_yyyymmdd}"

logfile="${privatedir}/${WIKI}/${startdate_yyyymmdd}/dumplog_fillin.$$"
WIKIFIRSTLETTER="${WIKI:0:1}"

# we might have more than one worker host running this script for different part ranges, so the status file
# needs to be per part range
partrange_hyphen=${PARTRANGE//,/-}
statusfile="${dumpstempdir}/${WIKIFIRSTLETTER}/${WIKI}/${WIKI}-fixups-${startdate_yyyymmdd}-${partrange_hyphen}-status.txt"

logit "getting stubs" INFO
get_stubs "$PARTRANGE"

logit "checking that stubs are present" INFO
check_all_stubs_present "$PARTRANGE" || exit 1

logit "getting parts list" INFO
get_parts "$PARTRANGE" || exit 1

logit "getting jobinfo arg" INFO
get_jobinfo_arg "$PARTRANGE" || exit 1
logit "jobinfo_arg: $jobinfo_arg" INFO

logit "doing fillin" INFO
do_fillin "$jobinfo_arg"
logit "really done" INFO
exit 0
