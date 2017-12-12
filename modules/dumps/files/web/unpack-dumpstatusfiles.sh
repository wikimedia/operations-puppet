#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/web/unpack-dumpstatusfiles.sh
##############################

# This script checks for the arrival of a tarball
# of dump status files; if a new one has arrived, it unpacks
# the tarball in the appropriate location.
#
# This ensures that html and other dumps status files
# on public-facing servers always reflect dump content
# files that have actually been made available via
# rsync from internal servers.

usage() {
    cat<<EOF
Usage: $0 --xmldumpsdir <path> --newer <minutes>

  --xmldumpsdir   path to root of xml/sql dumps tree for unpacking tarball
  --newer         file must be newer than this many minutes ago to unpack it

Example:  $0 --xmldumpsdir /data/xmldatadumps/public --newer 10
EOF
    exit 1
}

xmldumpsdir=""
newer=""

while [ $# -gt 0 ]; do
    if [ $1 == "--xmldumpsdir" ]; then
        xmldumpsdir="$2"
        shift; shift
    elif [ $1 == "--newer" ]; then
        newer="$2"
        shift; shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$xmldumpsdir" ]; then
    echo "$0: missing argument --xmldumpsdir"
    usage && exit 1
elif [ -z "$newer" ]; then
    echo "$0: missing argument --newer"
    usage && exit 1
fi

tarballpath="${xmldumpsdir}/dumpstatusfiles.tar.gz"
if [ ! -e "$tarballpath" ]; then
    # no file so do no check
    exit 0
fi

result=$( /usr/bin/find "$tarballpath" -mmin "-${newer}" )

if [ -n "$result" ]; then
        cd "$xmldumpsdir"
	/bin/zcat "$tarballpath" | /bin/tar xfp -
fi
