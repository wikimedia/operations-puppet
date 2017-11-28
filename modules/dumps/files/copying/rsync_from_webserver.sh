#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/copying/rsync_from_webserver.sh
##############################

# This script rsyncs xml/sql dumps to fallback web servers or other servers
# that host a full copy of dumps and datasets.
#
# It expects to be run as root, since it preserves owners and permissions.
#
# It will not run if there is already an rsync of some sort running to/from
# the destination host as the root user, no point in competing for
# bandwidth. Also no point in running a second copy if this script itself
# is already running.

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

excludes="--exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog'"
args="--contimeout=600 --timeout=600 --bwlimit=40000 --delete"

# /usr/bin/pgrep -f -x /usr/bin/rsync -rlptq $bwlimit ${sourcehost}::${srcpath} ${destroot}/${destpath}
isrunning=$( /usr/bin/pgrep -u root -f "/usr/bin/rsync .* ${desthost}::" )
if [ -n "$isrunning" ]; then
    exit 0
fi

# sample command:
# /usr/bin/rsync --bwlimit=40000 -aq --delete --exclude='**bad/' --exclude='**save/' --exclude='**not/' \
#       --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog' \
#       /data/xmldatadumps/public/other/ ms1001.wikimedia.org::data/xmldatadumps/public/other/
/usr/bin/rsync $args -aq $excludes --exclude=/other/ /data/xmldatadumps/public/  ${desthost}::data/xmldatadumps/public/
/usr/bin/rsync $args -aq $excludes /data/xmldatadumps/public/other/ ${desthost}::data/xmldatadumps/public/other/
