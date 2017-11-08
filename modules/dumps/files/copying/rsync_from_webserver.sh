#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/copying/rsync_from_webserver.sh
##############################

# This script rsyncs xml/sql dumps to fallback web servers or other servers
# that host a full copy of dumps and datasets.

usage() {
    cat<<EOF
Usage: $0 --desthost <hostname>

  --desthost   fqdn of host to which to rsync

Example: $0 --desthost ms1001.wikimedia.org
EOF
    exit 1
}

desthost=""

while [ $# -gt 0 ]; do
    if [ $1 == "--desthost" ]; then
        desthost="$2"
        shift; shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$desthost" ]; then
    echo "$0: missing argument --desthost"
    usage && exit 1
fi

excludes="--exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/'--exclude='*.inprog'"
args="--contimeout=600 --timeout=600 --bwlimit=40000 --delete"

# /usr/bin/pgrep -f -x /usr/bin/rsync -rlptq $bwlimit ${sourcehost}::${srcpath} ${destroot}/${destpath}
isrunning=$( /usr/bin/pgrep  -f /usr/bin/rsync stuff "${desthost}::" )
if [ $isrunning ]; then
    exit 0
fi

# /usr/bin/rsync --bwlimit=40000 -a --delete -q --exclude=wikidump_* --exclude=md5temp.* \ 
#    --exclude=*.inprog /data/xmldatadumps/public/other/ ms1001::data/xmldatadumps/public/other/
/usr/bin/rsync $args -a $excludes --exclude=/other/ /data/xmldatadumps/public/  ${desthost}::data/xmldatadumps/public/   > /dev/null 2>&1
/usr/bin/rsync $args -a $excludes /data/xmldatadumps/public/other/ ${desthost}::data/xmldatadumps/public/other/  > /dev/null 2>&1
