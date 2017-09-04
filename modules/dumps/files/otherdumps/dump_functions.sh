#!/bin/bash
#############################################################
# This file is maintained by puppet!
# modules/dumps/otherdumps/dump_functions.sh
#############################################################
#
# functions used by "other" dumps cron jobs (not the main xml/sql ones)

source /usr/local/etc/set_dump_dirs.sh

checkval() {
    setting=$1
    value=$2
    if [ -z "$value" -o "$value" == "null" ]; then
        echo "failed to retrieve value of $setting from $configfile" >& 2
        exit 1
    fi
}

getsetting() {
    results=$1
    section=$2
    setting=$3
    echo "$results" | /usr/bin/jq -M -r ".$section.$setting"
}


standard_usage() {
    echo "Usage: $0 --confsdir <path> --repodir <path> --otherdumpsdir <path>"
    echo
    echo "  --confsdir       path to dir with configuration files for dump generation"
    echo "  --repodir        path to dir with scripts for dump generation"
    echo "  --otherdumpsdir  path to dir where misc dump output files are written"
}

get_standard_opts() {
    while [ $# -gt 0 ]; do
        if [ $1 == "--confsdir" ]; then
		confsdir="$2"
		shift; shift;
        elif [ $1 == "--repodir" ]; then
		repodir="$2"
		shift; shift;
        elif [ $1 == "--otherdumpsdir" ]; then
		otherdumpsdir="$2"
		shift; shift;
        else
		echo "$0: Unknown option $1"
		standard_usage
                exit 1
        fi
    done
}
