#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/web/cleanup_old_miscdumps.sh
##############################

# This script removes old files produced by misc dump
# cron jobs, on hosts where they are rsynced over from
# the generating host.

# We clean them up here rather than rsync --delete,
# because we keep and serve more of these on web
# and other servers than on the generating host.

usage() {
    cat<<EOF
Usage: $0 --miscdumpsdir <path>

  --miscdumpsdir  path to root of misc dumps tree
  --configfile    path to config file describing dirs and cleanup info
  --dryrun        don't remove anything, print what would be done

Example:  $0 --miscdumpsdir /data/xmldatadumps/other --configfile /etc/dumps/confs/cleanup_misc.conf
EOF
    exit 1
}

miscdumpsdir=""
configfile=""
dryrun=""

while [ $# -gt 0 ]; do
    if [ $1 == "--miscdumpsdir" ]; then
        miscdumpsdir="$2"
        shift; shift
    elif [ $1 == "--configfile" ]; then
        configfile="$2"
        shift; shift
    elif [ $1 == "--dryrun" ]; then
	dryrun="yes"
        shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$miscdumpsdir" ]; then
    echo "$0: missing argument --miscdumpsdir"
    usage && exit 1
elif [ -z "$configfile" ]; then
    echo "$0: missing argument --configfile"
    usage && exit 1
fi

if [ ! -d "$miscdumpsdir" ]; then
    echo "no such directory $miscdumpsdir"
    exit 1
fi

cd "$miscdumpsdir" || exit 1
config_entries=$( cat $configfile | grep ':' | grep -v '^#' )
# globalblocks:6
# cirrussearch:10

for entry in $config_entries; do
  IFS=':' read -r subdir keep <<<$entry

  if [ ! -d "$subdir" ]; then
      echo "subdir $subdir does not exist, skipping"
      continue
  elif [[ ! "$keep" =~ ^[0-9]+$ ]]; then
      echo "keep value $keep is not a number, skipping"
      continue
  fi

  runs=$( cd "$subdir"; ls -d [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] | sort )
  if [ -z "$runs" ]; then
      continue
  fi

  runs=( $runs )
  numruns=${#runs[@]}
  if [ $numruns -le $keep ]; then
      continue
  fi

  num_unwanted=$(( $numruns - $keep ))
  unwanted=${runs[@]:0:${num_unwanted}}
  for dirname in ${unwanted[@]}; do
      if [ -n "$dryrun" ]; then
	  echo "would rm -rf ${subdir}/${dirname}"
      else
	  rm -rf "${subdir}/${dirname}"
      fi
  done

done


