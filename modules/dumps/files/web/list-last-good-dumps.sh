#!/bin/bash
#############################################################
# This file is maintained by puppet!
# /modules/dumps/web/list-last-good-dumps.sh
#############################################################

# This script dumps lists of directories and/or files produced
# for the last n good xml/sql dump runs, for a variety of 'n'
# and in several different formats.  These can be used by our
# mirrors, and also used by rsync jobs internally.

usage() {
    cat<<EOF
Usage: $0 --xmldumpsdir <path>

  --xmldumpsdir   path to root of xml/sql dumps tree

Example:  $0 --xmldumpsdir /data/xmldatadumps/public
EOF
    exit 1
}

xmldumpsdir=""

while [ $# -gt 0 ]; do
    if [ $1 == "--xmldumpsdir" ]; then
        xmldumpsdir="$2"
        shift; shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$xmldumpsdir" ]; then
    echo "$0: missing argument --xmldumpsdir"
    usage && exit 1
fi

# generate lists of most recent completed successful dumps for rsync (dirs, files)
/usr/bin/python3 /usr/local/bin/list-last-n-good-dumps.py --dumpsnumber 1,2,3,4,5 --dirlisting 'rsync-dirlist-last-%s-good.txt' --rsynclists --relpath --outputdir "${xmldumpsdir}/" --dumpsdir "${xmldumpsdir}/"
/usr/bin/python3 /usr/local/bin/list-last-n-good-dumps.py --dumpsnumber 1,2,3,4,5 --filelisting 'rsync-filelist-last-%s-good.txt' --rsynclists --relpath --outputdir "${xmldumpsdir}/" --toplevel --dumpsdir "${xmldumpsdir}/"
# these lists can be used for rsync excl/incl on our side, providing shares that "just work" for the mirrors
/usr/bin/python3 /usr/local/bin/list-last-n-good-dumps.py --dumpsnumber 1,2,3,4,5 --rsynclisting 'rsync-inc-last-%s.txt' --relpath --outputdir "${xmldumpsdir}/" --toplevel --dumpsdir "${xmldumpsdir}/"
