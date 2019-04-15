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
Usage: $0 --xmldumpsdir <path> --xmlremotedirs <path>,<path>,<path>...  \\
          --miscdumpsdir <path> --miscremotedirs <path>,<path>,<path>...

  --xmldumpsdir   path to root of xml/sql dumps tree for rsync to peer hosts
  --xmlremotedirs  comma-separated list of remote destinations to which to rsync

  --miscdumpsdir   path to root of misc dumps tree for rsync to peer hosts
  --miscremotedirs  comma-separated list of remote destinations to which to rsync

Example:

 $0 --xmldumpsdir /data/xmldatadumps/public \\
   --xmlremotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,dumpsdata1003.eqiad.wmnet::data/xmldatadumps/public/ \\
   --miscdumpsdir /data/otherdumps \\
   --miscremotedirs dumpsdata1002.eqiad.wmnet::data/otherdumps/,dumpsdata1003.eqiad.wmnet::data/otherdumps/
EOF
    exit 1
}

make_statusfiles_tarball() {
    # make tarball of all xml/sql dumps status and html files
    tarballpath="${xmldumpsdir}/dumpstatusfiles.tar"
    tarballpathgz="${tarballpath}.gz"

    # Only pick up the html/json/txt files from the latest run; even if it's
    # only partially done or for some wikis it's not started, that's fine.
    # Files from the previous run will have already been sent over before
    # the new run started, unless there are 0 minutes between end of
    # one dump run across all wikis and start of the next (in which case
    #  we are cutting things WAY too close with the runs)
    latestwiki=$( cd "$xmldumpsdir"; ls -td *wik* | head -1 )

     rm -f "$tarballpathgz"

    # dirname is YYYYMMDD, i.e. 8 digits. ignore all other directories.
    latestrun=$( cd "${xmldumpsdir}/${latestwiki}" ; ls -d [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] | sort | tail -1 )
    if [ -n "$latestrun" ]; then

	# top-level index files first
        ( cd "$xmldumpsdir"; /bin/tar cfp "$tarballpath" *html *json )
        # add per-wiki files next: ( cd /data/xmldatadumps/public; /usr/bin/find . -maxdepth 3 -regextype sed -regex ".*/20171120/.*\(json\|html\|txt\)" )
        ( cd "$xmldumpsdir"; /usr/bin/find "." -maxdepth 3 -regextype sed -regex ".*/${latestrun}/.*\.\(json\|html\|txt\)" | /usr/bin/xargs -s 1048576 /bin/tar rfp "$tarballpath" )
	# add txt files from 'latest' directory, they also will be skipped by the regular rsync
	( cd "$xmldumpsdir"; /usr/bin/find "." -maxdepth 3 -regextype sed -regex ".*/latest/.*\.txt" | /usr/bin/xargs -s 1048576 /bin/tar rfp "$tarballpath" )
        # if no files found, there will be no tarball created either
	if [ -f "$tarballpath" ]; then
            /bin/gzip "$tarballpath"
        fi
    fi
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
    elif [ $1 == "--miscdumpsdir" ]; then
        miscdumpsdir="$2"
        shift; shift
    elif [ $1 == "--miscremotedirs" ]; then
        miscremotedirs="$2"
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
elif [ -z "$miscremotedirs" ]; then
    echo "$0: missing argument --miscremotedirs"
    usage && exit 1
fi

IFS_SAVE=$IFS
IFS=','
read -a xmlremotedirs_list <<<$xmlremotedirs
read -a miscremotedirs_list <<<$miscremotedirs
IFS=$IFS_SAVE

BWLIMIT=80000
while [ 1 ]; do
    # rsync of xml/sql dumps for public wikis
    for dest in $xmlremotedirs_list; do
        # do this for each remote; if we do it once and then do all the rsyncs
        # back to back, the status files in the tarball may be quite stale
        # by the time they arrive at the last host
        make_statusfiles_tarball

        /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT --exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog'  --exclude='*.html' --exclude='*.txt' --exclude='*.json' ${xmldumpsdir}/*wik* "$dest" > /dev/null 2>&1

	# send statusfiles tarball over last, remote can unpack it when it notices the arrival
	# this way, content of status and html files always reflects dump output already
	# made available via rsync
        if [ -f "$tarballpathgz" ]; then
            /usr/bin/rsync -pgo  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT "$tarballpathgz" "$dest" > /dev/null 2>&1
        fi

    done

    # rsync of misc dumps, not necessarily to/from the same tree as the public wikis
    for dest in $miscremotedirs_list; do
        /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT --exclude='*.lock' ${miscdumpsdir}/* "$dest" > /dev/null 2>&1
    done

    # when dumps aren't being generated, no reason to try over and over again to push new files.
    # take a break in between.
    sleep 600
done
