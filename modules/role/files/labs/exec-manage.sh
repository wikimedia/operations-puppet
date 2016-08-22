#!/bin/bash

# This script helps manage Grid Engine exec nodes by allowing for depool,
# repool, and check status, given an exec node hostname.

# Usage: exec-manage.sh exec_host_name [status|depool|repool|test]
# Example: ./exec-manage.sh tools-exec1001.eqiad.wmflabs status

set -e


if [ "$#" -ne 2 ]; then
    echo "Wrong number of parameters"
    echo "Usage: exec-manage.sh exec_host_name [status|depool|repool|test] "
    exit 1
fi

exec_host=$1
cmd=$2

case $cmd in
    status)

        # List count of running jobs on host
        echo "Count of jobs running on host $exec_host : "
        /usr/bin/qhost -j -h $exec_host | awk '{print $1; }' | grep -E ^[0-9] | wc -l

        echo

        # List details of jobs running on host
        echo "Jobs running on host $exec_host : "
        /usr/bin/qhost -j -h $exec_host

        echo

        # Also check status of queues on host
        echo "Status of queues on this host (States - d = disabled) : "
        /usr/bin/qstat -f -q "*@$exec_host"

        ;;

    depool)

        # Collect the list of jobs running on this host, and convert them
        # to pipe separated string, this is useful to show status of these jobs
        # after the drain
        job_list=`/usr/bin/qhost -j -h $exec_host |
                      awk '{print $1; }' |
                      grep -E ^[0-9] |
                      awk -vORS='|' '{print $1; }'`


        # Disable all the queues running on this host. The *@ is a special
        # syntax that means 'all queues @ host'
        /usr/bin/qmod -d "*@$exec_host"

        # List all the jobs running on the host, and attempt to reschedule them,
        # match jobs that say 'are not rerunable' and delete them (these need
        # to be rescheduled manually)
        /usr/bin/qhost -j -h $exec_host |
            awk '{ print $1; }' |
            egrep ^[0-9] |
            xargs -L1 qmod -rj |
            grep 'are not rerunable' |
            awk '{ print $3; }' |
            xargs --no-run-if-empty -L1 qdel

        echo "This exec node has been depooled, and jobs that were running \
              prior have been rescheduled (if rerunable). Current status: "
        /usr/bin/qhost -j | grep -E "${job_list%|*}"

        ;;

    repool)

        # Enables all queues on this host
        /usr/bin/qmod -e "*@$exec_host"

        # Fall-through to test
        ;&

    test)

        # Determine release version of Exec node. Logic for now:
        # Hosts with 14xx - Trusty, 12xx - Precise
        case "$exec_host" in
            *"14"*)
                release="trusty"
                ;;
            *"12"*)
                release="precise"
                ;;
        esac

        echo "Submitting a test job to $exec_host"

        # Submit a test job to a recently repooled host to make sure it accepts
        # new jobs
        /usr/bin/qsub -l hostname=$exec_host -l release=$release \
            -b y "date && sleep 60 && date"

        # Wait 1 second and display the output of qstat
        sleep 1
        echo "Output of qstat: "
        /usr/bin/qstat

        ;;

    *)

        # Print usage
        echo "Usage: exec-manage.sh exec_host_name [status|depool|repool|test]"

        ;;

esac
