#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/generation/rsync-to-peers.sh
##############################

# This script rsyncs xml/sql dumps and misc dumps to fallback dumps
# generation nfs servers, i.e. to its peers.
#
# This ensures that we never have more than one rsync connection going
# at a time on the host where dumps are written as they are generated.

usage() {
    cat<<EOF
Usage: $0 --dumpsdir <path> --xmlremotedirs <path>,<path>,<path>...

  --xmldumpsdir   path to root of xml/sql dumps tree for rsync to peer hosts
  --xmlremotedirs  comma-separated list of remote destinations to which to rsync

  --miscdumpsdir   path to root of misc dumps tree for rsync to peer hosts
  --miscremotedirs  comma-separated list of remote destinations to which to rsync

Example:

 $0 --xmldumpsdir /data/xmldatadumps \\
   --xmlremotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,dumpsdata1003.eqiad.wmnet::data/xmldatadumps/public/ \\
   --miscdumpsdir /data/otherdumps \\
   --miscremotedirs dumpsdata1002.eqiad.wmnet::data/otherdumps/,dumpsdata1003.eqiad.wmnet::data/otherdumps/
EOF
    exit 1
}

xmldumpsdir=""
xmlremotedirs=""
miscdumpsdir=""
miscremotedirs=""

while [ $# -gt 0 ]; do
    if [ $1 == "--xmldumpsdir" ]; then
        xmldumpsdir="$2"
        shift; shift
    elif [ $1 == "--xmlremotedirs" ]; then
        xmlremotedirs="$2"
        shift; shift
    elif [ $1 == "--miscdumpdir" ]; then
        xmlremotedirs="$2"
        shift; shift
    elif [ $1 == "--miscremotedirs" ]; then
        xmlremotedirs="$2"
        shift; shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$xmldumpsdir" ]; then
    echo "$0: missing argument --xmldumpsdir"
    usage && exit 1
elif [ -z "$xmlremotedirs" ]; then
    echo "$0: missing argument --xmlremotedirs"
    usage && exit 1
elif [ -z "$miscdumpsdir" ]; then
    echo "$0: missing argument --miscdumpsdir"
    usage && exit 1
elif [ -z "$miscemotedirs" ]; then
    echo "$0: missing argument --miscremotedirs"
    usage && exit 1
fi

IFS_SAVE=$IFS
IFS=','
read -a xmlremotedirs_list <<<$xmlremotedirs
read -a miscremotedirs_list <<<$miscremotedirs
IFS=$IFS_SAVE

while [ 1 ]; do

    # rsync of xml/sql dumps for public wikis
    for dest in $xmlremotedirs_list; do
	/usr/bin/rsync -a  --contimeout=600 --timeout=600 ${xmldumpsdir}/public/*html "$dest" > /dev/null 2>&1
        /usr/bin/rsync -a  --contimeout=600 --timeout=600 --exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog'  ${dumpsdir}/public/*wik* "$dest" > /dev/null 2>&1
    done

    # rsync of misc dumps, not necessarily to/from the same tree as the public wikis
    for dest in $miscremotedirs_list; do
        /usr/bin/rsync -a  --contimeout=600 --timeout=600 ${miscdumpsdir}/* "$dest" > /dev/null 2>&1
    done

    # when dumps aren't being generated, no reason to try over and over again to push new files.
    # take a break in between.
    sleep 600

done
