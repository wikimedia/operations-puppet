#!/bin/bash
#
# NAME
# jobs-loop.sh -- Continuously process a MediaWiki jobqueue
#
# SYNOPSIS
# jobs-loop.sh [-t timeout] [-v virtualmemory] [job_type]
#
# DESCRIPTION
# jobs-loop.sh is an infinite "while loop" used to call MediaWiki runJobs.php
# and eventually attempt to process any job enqueued. MediaWiki jobs are split
# into several types, by default jobs-loop.sh will:
#  - first attempt to run the internally priorized jobs (see `types` variable
#    in script).
#  - proceed any default jobs
#
# MediaWiki configuration variable $wgJobTypesExcludedFromDefaultQueue is used
# to exclude some types from the default processing. Those excluded job types
# could be processed on dedicated boxes by running jobs-loop.sh using the
# job_type parameter.
#
# You will probably want to run this script under your webserver username.
#
# Example:
# // Process job queues:
# jobs-loop.sh
#
# // Process jobs of type `webVideoTranscode` with a maxtime of 4 hours
# jobs-loop.sh -t 14400 webVideoTranscode
#

# default maxtime for jobs
maxtime=300
maxvirtualmemory=400000

# Whether to process the default queue. Will be the case if no job type
# was specified on the command line. Else we only want to process given types
dodefault=true

while getopts "t:v:" flag
do
	case $flag in
		t)
			maxtime=$OPTARG
			;;
		v)
			maxvirtualmemory=$OPTARG
			;;
	esac
done
shift $(($OPTIND - 1))

# Limit virtual memory
if [ "$maxvirtualmemory" -gt 0 ]; then
	ulimit -v $maxvirtualmemory
fi

# When killed, make sure we are also getting ride of the child jobs
# we have spawned.
trap 'kill %-; exit' SIGTERM


if [ -z "$1" ]; then
	echo "Starting default queue job runner"
	dodefault=true
	#types="htmlCacheUpdate sendMail enotifNotify uploadFromUrl fixDoubleRedirect renameUser"
	types="sendMail enotifNotify uploadFromUrl fixDoubleRedirect MoodBarHTMLMailerJob ArticleFeedbackv5MailerJob RenderJob"
else
	echo "Starting type-specific job runner: $1"
	dodefault=false
	types=$1
fi

# Starting the infinite loop of doom
cd `readlink -f /usr/local/apache/common/multiversion`
while [ 1 ];do

	# Do the prioritised types
	moreprio=y
	while [ -n "$moreprio" ] ; do
		moreprio=
		for type in $types; do
			db=`php -n MWScript.php nextJobDB.php --wiki=aawiki --type="$type"`
			if [ -n "$db" ]; then
				echo "$db $type"
				nice -n 20 php MWScript.php runJobs.php --wiki="$db" --procs=5 --type="$type" --maxtime=$maxtime &
				wait
				moreprio=y
			fi
		done
	done

	if $dodefault; then
		# Do the remaining types
		db=`php -n MWScript.php nextJobDB.php --wiki=aawiki`

		if [ ! -z "$db" ];then
			echo "$db"
			nice -n 20 php MWScript.php runJobs.php --wiki="$db" --procs=5 --maxtime=$maxtime &
			wait
		fi
	fi

	# No jobs to do, wait for a while
	echo "No jobs..."
	sleep 5

done
