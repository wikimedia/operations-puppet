#!/bin/bash
#
# NAME
# jobs-loop.sh -- Continuously process a MediaWiki jobqueue
#
# SYNOPSIS
# jobs-loop.sh [-j job_type] [-t maxtime]
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
# jobs-loop.sh -j webVideoTranscode -t 14400
#

# Limit virtual memory
ulimit -v 400000

# When killed, make sure we are also getting ride of the child jobs
# we have spawned.
trap 'kill %-; exit' SIGTERM


# Whether to process the default queue. Will be the case if no job type
# was specified on the command line. Else we only want to process given types
dodefault=true
#types="htmlCacheUpdate sendMail enotifNotify uploadFromUrl fixDoubleRedirect renameUser"
types="sendMail enotifNotify uploadFromUrl fixDoubleRedirect MoodBarHTMLMailerJob ArticleFeedbackv5MailerJob RenderJob"

# default maxtime for jobs
maxtime=300

while getopts "j:t:" flag
do
	case $flag in
		j)
			types=$OPTARG
			dodefault=false
			;;
		t)
			maxtime=$OPTARG
			;;
	esac
done

if [ $dodefault == true ]; then
	echo "Starting default queue job runner"
else
	echo "Starting type-specific job runner: $types"
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
