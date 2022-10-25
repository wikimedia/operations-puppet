#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/generation/rsync-via-primary.sh
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

source /usr/local/bin/rsyncer_lib.sh

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
  --miscremotesubs     comma-separated list of remote internal destinations to which to rsync

  --do_xml_tarball     make a tarball of xml/sql dump index.html files; you will want
                       to do this only if the xml files are generated on this host
  --do_rsync_xml       rsync xml dumps to remote server(s)
  --do_rsync_misc      rsync misc dumps to remote server(s)
  --do_rsync_miscsubs  rsync misc dump subdirs to remote server(s)

  --dryrun             don't do any rsyncs, print out the commands that would be run
Example:

(single xml/sql and misc dumps producer)

 $0 --xmldumpsdir /data/xmldatadumps/public \\
   --xmlremotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,clouddumps1001.wikimedia.org::data/xmldatadumps/public/,clouddumps1002.wikimedia.org::data/xmldatadumps/public/ \\
   --miscdumpsdir /data/otherdumps \\
   --miscremotedirs dumpsdata1002.eqiad.wmnet::data/otherdumps/,clouddumps1001.wikimedia.org::data/xmldatadumps/public/,clouddumps1002.wikimedia.org::data/xmldatadumps/public/ \\
   --miscremotesubdirs incr,categoriesrdf \\
   --miscremotedirs dumpsdata1003.eqiad.wmnet::data/otherdumps/ \\
   --do_tarball --do_rsync_xml --do_rsync_misc --do_rsync_miscsubs

or:

(xml/sql dumps producer separate from misc dumps producer)

 $0 --xmldumpsdir /data/xmldatadumps/public \\
   --xmlremotedirs dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,clouddumps1001.wikimedia.org::data/xmldatadumps/public/,clouddumps1002.wikimedia.org::data/xmldatadumps/public/ \\
   --do_tarball --do_rsync_xml

and

 $0 --miscdumpsdir /data/otherdumps \\
   --miscremotedirs dumpsdata1002.eqiad.wmnet::data/otherdumps/,clouddumps1001.wikimedia.org::data/xmldatadumps/public/,clouddumps1002.wikimedia.org::data/xmldatadumps/public/ \\
   --miscsubdirs incr,categoriesrdf \\
   --miscremotedirs dumpsdata1003.eqiad.wmnet::data/otherdumps/ \\
   --do_rsync_misc --do_rsync_miscsubs

EOF
    exit 1
}

declare -A opts
declare -A flags

while [ $# -gt 0 ]; do
    case "$1" in
	"--xmldumpsdir")        opts[xmldumpsdir]="$2";    shift                ;;
	"--xmlremotedirs")      opts[xmlremotedirs]="$2";  shift                ;;
	"--miscdumpsdir")       opts[miscdumpsdir]="$2";   shift                ;;
	"--miscremotedirs")     opts[miscremotedirs]="$2"; shift                ;;
	"--miscsubdirs")        opts[miscsubdirs]="$2";    shift                ;;
	"--miscremotesubs")     opts[miscremotesubs]="$2"; shift                ;;
	"--do_tarball")         flags[do_tarball]="true"                        ;;
	"--do_rsync_xml")       flags[do_rsync_xml]="true"                      ;;
	"--do_rsync_misc")      flags[do_rsync_misc]="true"                     ;;
	"--do_rsync_miscsubs")  flags[do_rsync_miscsubs]="true"                 ;;
	"--dryrun")             flags[dryrun]="true"; flags[onepass]="true"     ;;
	"--test")               flags[testrun]="true"; flags[onepass]="true"    ;;
	"--onepass")            flags[onepass]="true"                           ;;
	*)
            echo "$0: Unknown option $1" >& 2
            usage
	    ;;
    esac
    shift
done

if [ "${flags[do_rsync_xml]}" ]; then
    if [ -z "${opts[xmldumpsdir]}" ]; then
	echo "$0: missing argument --xmldumpsdir"
	usage && exit 1
    elif [ -z "${opts[xmlremotedirs]}" ]; then
       echo "$0: missing argument --xmlremotedirs"
        usage && exit 1
    fi
fi

if [ "${flags[do_rsync_misc]}" ]; then
    if [ -z "${opts[miscdumpsdir]}" ]; then
	echo "$0: missing argument --miscdumpsdir"
	usage && exit 1
    elif [ -z "${opts[miscremotedirs]}" ]; then
	echo "$0: missing argument --miscremotedirs"
	usage && exit 1
    fi
fi

if [ "${flags[do_rsync_miscsubs]}" ]; then
    if [ -z "${opts[miscsubdirs]}" ]; then
	echo "$0: missing argument --miscsubdirs"
        usage && exit 1
    elif [ -z "${opts[miscremotesubs]}" ]; then
        echo "$0: missing argument --miscremotesubs"
        usage && exit 1
    elif [ -z "${opts[miscdumpsdir]}" ]; then
	echo "$0: missing argument --miscdumpsdir"
	usage && exit 1
    fi
fi

declare -A dirs

if [ "${flags[do_rsync_xml]}" ]; then
    dirs[xmlremotedirs]=$( get_comma_sep "${opts[xmlremotedirs]}" )
fi
if [ "${flags[do_rsync_misc]}" ]; then
    dirs[miscremotedirs]=$( get_comma_sep "${opts[miscremotedirs]}" )
fi
if [ "${flags[do_rsync_miscsubs]}" ]; then
    dirs[miscremotesubs]=$( get_comma_sep "${opts[miscremotesubs]}" )
    dirs[misclocalsubs]=$( get_comma_sep "${opts[miscsubdirs]}" )
fi

BWLIMIT=80000
set_rsync_stdargs "$BWLIMIT"

if [ "${flags[testrun]}" ]; then
    /bin/rm -f /tmp/dumpsrsync_test.txt
fi

init_rlib "${flags[testrun]}" "${flags[dryrun]}"

while true; do

    if [ "${flags[do_rsync_xml]}" ]; then

        # rsync of xml/sql dumps for public wikis
        for dest in ${dirs[xmlremotedirs]}; do
            # do this for each remote; if we do it once and then do all the rsyncs
            # back to back, the status files in the tarball may be quite stale
            # by the time they arrive at the last host
            if [ "${flags[do_tarball]}" ]; then
		tarballpathgz=$( make_statusfiles_tarball "${opts[xmldumpsdir]}" )
            fi

	    push_dumpfiles "${opts[xmldumpsdir]}" "$dest"
	    push_tarball "$tarballpathgz" "$dest"
        done

   fi
   if [ "${flags[do_rsync_misc]}" ]; then
       for dest in ${dirs[miscremotedirs]}; do
	   push_misc_dumps "${opts[miscdumpsdir]}" "$dest"
       done
   fi
   if [ "${flags[do_rsync_miscsubs]}" ]; then

       # rsync of limited subdirs of misc dumps to internal, not necessarily to/from the same tree as the public wikis
       # these internal hosts only need data they will use in future misc dumps generation, not the entire tree
       for subdir in ${dirs[misclocalsubs]}; do
	   for dest in ${dirs[miscremotesubs]}; do
	       push_misc_subdirs "${opts[miscdumpsdir]}" "$dest" "$subdir"
	   done
       done

   fi

   if [ "${flags[onepass]}" ]; then
       exit 0
   fi

    # when dumps aren't being generated, no reason to try over and over again to push new files.
    # take a break in between.
    sleep 600
done
