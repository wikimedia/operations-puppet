#!/bin/bash
# schedule a host downtime in Icinga
# Daniel Zahn (dzahn) 20150513 - T79842
#

usage() {
    cat<<EOF
Usage: $0  -h <hostname> -d <duration-seconds> -r <reason>
Example: ./icinga-downtime -h mw1021 -d 7200 -r "something happened"

Options:
 -h  short name of a host as shown in the Icinga UI
 -d  length of the downtime, in seconds
     default 7200 (2h)
 -r  a string with the reason for the downtime
EOF
}

commandfile="/var/lib/nagios/rw/nagios.cmd"
logfile="/var/log/icinga/icinga.log"
user="marvin-bot" # because it's a _down_time bot, get it?:p

while getopts "h:d:r:" opts; do
case $opts in
    h)
        hostname=$OPTARG
    ;;
    d)
        duration=$OPTARG
    ;;
    r)
        reason=$OPTARG
    ;;
    \?)
        echo "invalid option: '$OPTARG'"
        usage
        exit 1
    ;;
    :)
        echo "option '$OPTARG' requires an argument"
        usage
        exit 1
    ;;
esac
done

if [ -z "$hostname" ] || [ -z "$reason" ]; then
    usage
    exit 1
fi

if [ -z "$duration" ]; then
    duration=7200
fi

start_time=$(date +%s) # now
end_time=$(( $start_time + $duration ))

printf "[%lu] SCHEDULE_HOST_DOWNTIME;${hostname};${start_time};${end_time};1;0;${duration};${user};${reason}\n" $(date +%s) > $commandfile
printf "[%lu] SCHEDULE_HOST_SVC_DOWNTIME;${hostname};${start_time};${end_time};1;0;${duration};${user};${reason}\n" $(date +%s) > $commandfile

tail -f $logfile | grep -m2 $hostname

