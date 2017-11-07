#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/generation/rsync-to-peers.sh
##############################

# This script rsyncs xml/sql dumps to fallback dumps generation nfs servers,
# i.e. to its peers.
# Eventually it will also rsync all output from misc dump cron jobs to
# these servers.
# This ensures that we never have more than one rsync connection going
# at a time on the host where dumps are written as they are generated.

usage() {
    cat<<EOF
Usage: $0 --dumpsdir <path> --remotedirs <path>,<path>,<path>...

  --dumpsdir   path to root of dumps tree for rsync to peer hosts
  --remotedir  comma-separated list of remote destinations to which to rsync

Example: $0 --dumpsdir /data/xmldatadumps \\
   --remotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,dumpsdata1003.eqiad.wmnet::data/xmldatadumps/public/
EOF
    exit 1
}

dumpsdir=""
remotedirs=""

while [ $# -gt 0 ]; do
    if [ $1 == "--dumpsdir" ]; then
        dumpsdir="$2"
        shift; shift
    elif [ $1 == "--remotedirs" ]; then
        remotedirs="$2"
        shift; shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$dumpsdir" ]; then
    echo "$0: missing argument --dumpsdir"
    usage && exit 1
fi
if [ -z "$remotedirs" ]; then
    echo "$0: missing argument --remotedirs"
    usage && exit 1
fi

IFS_SAVE=$IFS
IFS=','
read -a remotedirs_list <<<$remotedirs
IFS=$IFS_SAVE

while [ 1 ]; do

    for dest in $remotedirs_list; do
	/usr/bin/rsync -a  --contimeout=600 --timeout=600 ${dumpsdir}/public/*html "$dest" > /dev/null 2>&1
        /usr/bin/rsync -a  --contimeout=600 --timeout=600 --exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog'  ${dumpsdir}/public/*wik* "$dest" > /dev/null 2>&1
    done

    # when dumps aren't being generated, no reason to try over and over again to push new files.
    # take a break in between.
    sleep 600

done
