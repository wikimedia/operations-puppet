#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/generation/rsync-to-peers.sh
##############################

# This script rsyncs xml/sql dumps and/or misc dumps to web, cloud nfs and
# fallback dumps generation nfs servers, i.e. to its peers.
#
# This ensures that we never have more than one rsync connection going
# at a time on the host where dumps are written as they are generated.
#
# Run this on nfs server holding xml/sql dumps as they are produced,
# and on nfs server holding misc dumps as they are produced (may be
# different servers).

usage() {
    cat<<EOF
Usage: $0 --xmldumpsdir <path> --xmlremotedirs <path>,<path>,<path>...  \\
          --miscdumpsdir <path> --miscremotedirs <path>,<path>,<path>...

  --xmldumpsdir        path to root of xml/sql dumps tree for rsync to peer hosts
  --xmlremotedirs      comma-separated list of remote destinations to which to rsync

  --miscdumpsdir       path to root of misc dumps tree for rsync to public-facing hosts
                       (i.e. web server)
  --miscremotedirs     comma-separated list of remote public-facing destinations to
                       which to rsync
  --miscsubdirs        comma-separated list of subdirs under miscdumpsdir root for
                       rsync to internal hosts (i.e. fallback dumpsdata hosts)
  --miscremotesubs     comma-separated list of remote destinations to which to rsync

  --do_xml_tarball     make a tarball of xml/sql dump index.html files; you will want
                       to do this only if the xml files are generated on this host
  --do_rsync_xml       rsync xml dumps to remote server(s)
  --do_rsync_misc      rsync misc dumps to remote server(s)
  --do_rsync_miscsubs  rsync misc dump subdirs to remote server(s)

  --dryrun             don't do any rsyncs, print out the commands that would be run
Example:

(single xml/sql and misc dumps producer)

 $0 --xmldumpsdir /data/xmldatadumps/public \\
   --xmlremotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,labstore1006.wikimedia.org::data/xmldatadumps/public/,labstore1007.wikimedia.org::data/xmldatadumps/public/ \\
   --miscdumpsdir /data/otherdumps \\
   --miscremotedirs dumpsdata1002.eqiad.wmnet::data/otherdumps/,labstore1006.wikimedia.org::data/xmldatadumps/public/,labstore1007.wikimedia.org::data/xmldatadumps/public/ \\
   --miscremotesubdirs incr,categoriesrdf \\
   --miscremotedirs dumpsdata1003.eqiad.wmnet::data/otherdumps/ \\
   --do_tarball --do_rsync_xml --do_rsync_misc --do_rsync_miscsubs

or:

(xml/sql dumps producer separate from misc dumps producer)

 $0 --xmldumpsdir /data/xmldatadumps/public \\
   --xmlremotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,labstore1006.wikimedia.org::data/xmldatadumps/public/,labstore1007.wikimedia.org::data/xmldatadumps/public/ \\
   --do_tarball --do_rsync_xml

and

 $0 --miscdumpsdir /data/otherdumps \\
   --miscremotedirs dumpsdata1002.eqiad.wmnet::data/otherdumps/,labstore1006.wikimedia.org::data/xmldatadumps/public/,labstore1007.wikimedia.org::data/xmldatadumps/public/ \\
   --miscsubdirs incr,categoriesrdf \\
   --miscremotedirs dumpsdata1003.eqiad.wmnet::data/otherdumps/ \\
   --do_rsync_misc --do_rsync_miscsubs

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
            /bin/gzip -S '.tmp' "$tarballpath"
	    mv "${tarballpath}.tmp" "$tarballpathgz"
        fi
    fi
}

xmldumpsdir=""
xmlremotedirs=""

miscdumpsdir=""
miscremotedirs=""

miscsubdirs=""
miscremotesubs=""

do_tarball=""
do_rsync_xml=""
do_rsync_misc=""
do_rsync_miscsubs=""

dryrun=""

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
    elif [ $1 == "--miscsubdirs" ]; then
        miscsubdirs="$2"
        shift; shift
    elif [ $1 == "--miscremotesubs" ]; then
        miscremotesubs="$2"
        shift; shift
    elif [ $1 == "--do_tarball" ]; then
        do_tarball="true"
        shift
    elif [ $1 == "--do_rsync_xml" ]; then
        do_rsync_xml="true"
        shift
    elif [ $1 == "--do_rsync_misc" ]; then
        do_rsync_misc="true"
        shift
    elif [ $1 == "--do_rsync_miscsubs" ]; then
        do_rsync_miscsubs="true"
        shift
    elif [ $1 == "--dryrun" ]; then
        dryrun="true"
        shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ "$do_rsync_xml" ]; then
    if [ -z "$xmldumpsdir" ]; then
	echo "$0: missing argument --xmldumpsdir"
	usage && exit 1
    elif [ -z "$xmlremotedirs" ]; then
       echo "$0: missing argument --xmlremotedirs"
        usage && exit 1
    fi
fi

if [ "$do_rsync_misc" ]; then
    if [ -z "$miscdumpsdir" ]; then
	echo "$0: missing argument --miscdumpsdir"
	usage && exit 1
    elif [ -z "$miscremotedirs" ]; then
	echo "$0: missing argument --miscremotedirs"
	usage && exit 1
    fi
fi

if [ "$do_rsync_miscsubs" ]; then
    if [ -z "$miscsubdirs" ]; then
	echo "$0: missing argument --miscsubdirs"
        usage && exit 1
    elif [ -z "$miscremotesubs" ]; then
        echo "$0: missing argument --miscremotesubs"
        usage && exit 1
    elif [ -z "$miscdumpsdir" ]; then
	echo "$0: missing argument --miscdumpsdir"
	usage && exit 1
    fi
fi

if [ "$do_rsync_xml" ]; then
    IFS_SAVE=$IFS
    IFS=','
    read -a xmlremotedirs_list <<<$xmlremotedirs
    IFS=$IFS_SAVE
fi
if [ "$do_rsync_misc" ]; then
    IFS_SAVE=$IFS
    IFS=','
    read -a miscremotedirs_list <<<$miscremotedirs
    IFS=$IFS_SAVE
fi
if [ "$do_rsync_miscsubs" ]; then
    IFS_SAVE=$IFS
    IFS=','
    read -a miscremotesubs_list <<<$miscremotesubs
    read -a miscsubdirs_list <<<$miscsubdirs
    IFS=$IFS_SAVE
fi

BWLIMIT=80000
while [ 1 ]; do

    if [ "$do_rsync_xml" ]; then

        # rsync of xml/sql dumps for public wikis
        for dest in ${xmlremotedirs_list[@]}; do
            # do this for each remote; if we do it once and then do all the rsyncs
            # back to back, the status files in the tarball may be quite stale
            # by the time they arrive at the last host
            if [ "$do_tarball" ]; then
                make_statusfiles_tarball
            fi

            if [ "$dryrun" ]; then
                echo /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT --exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog'  --exclude='*.html' --exclude='*.txt' --exclude='*.json' ${xmldumpsdir}/*wik* "$dest"
            else
                /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT --exclude='**bad/' --exclude='**save/' --exclude='**not/' --exclude='**temp/' --exclude='**tmp/' --exclude='*.inprog'  --exclude='*.html' --exclude='*.txt' --exclude='*.json' ${xmldumpsdir}/*wik* "$dest"  > /dev/null 2>&1
            fi
            # send statusfiles tarball over last, remote can unpack it when it notices the arrival
            # this way, content of status and html files always reflects dump output already
            # made available via rsync
            if [ -f "$tarballpathgz" ]; then
                if [ "$dryrun" ]; then
                    echo /usr/bin/rsync -pgo  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT "$tarballpathgz" "$dest"
                else
                    /usr/bin/rsync -pgo  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT "$tarballpathgz" "$dest" > /dev/null 2>&1
                fi
            fi

        done

   fi
   if [ "$do_rsync_misc" ]; then

       # rsync of misc dumps to public-facing hosts, not necessarily to/from the same tree as the public wikis
       # these hosts must get all the contents we have available
       for dest in ${miscremotedirs_list[@]}; do
           if [ "$dryrun" ]; then
               echo /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT ${miscdumpsdir}/* "$dest"
           else
               /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT ${miscdumpsdir}/* "$dest" > /dev/null 2>&1
           fi
       done

   fi
   if [ "$do_rsync_miscsubs" ]; then

       # rsync of limited subdirs of misc dumps to internal, not necessarily to/from the same tree as the public wikis
       # these internal hosts only need data they will use in future misc dumps generation, not the entire tree
       for subdir in $miscsubdirs_list; do
	   for dest in ${miscremotesubs_list[@]}; do
               if [ "$dryrun" ]; then
                   echo /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT ${miscdumpsdir}/${subdir} "$dest"
               else
                   /usr/bin/rsync -a  --contimeout=600 --timeout=600 --bwlimit=$BWLIMIT ${miscdumpsdir}/${subdir} "$dest" > /dev/null 2>&1
               fi
	   done
       done

   fi

    # when dumps aren't being generated, no reason to try over and over again to push new files.
    # take a break in between.
    sleep 600
done
