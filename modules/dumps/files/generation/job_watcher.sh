#!/bin/bash
# THIS FILE IS MAINTAINED BY PUPPET

AGE_DIFFERENCE=$(( 4*60*60 ))
AGE_DIFF_HOURS=4

usage() {
    cat<<EOF
Usage: $0 locksbasedir <path> dumpsbasedir <path>

  --locksbasedir   path to root of xml/sql dumps dir where per-wiki locks files may be found
  --dumpsbasedir   path to root of xml/sql dumps dir where per-wiki dump output files may be found
  --verbose        print the age diffs of all lockfiles found
Example:

 $0 --locksbasedir /data/xmldatadumps/private --dumpsbasedir /data/xmldatadumps/public
EOF
    exit 1
}

locksbasedir=""
dumpsbasedir=""
verbose=""

while [ $# -gt 0 ]; do
    if [ "$1" == "--locksbasedir" ]; then
        locksbasedir="$2"
        shift; shift
    elif [ "$1" == "--dumpsbasedir" ]; then
        dumpsbasedir="$2"
        shift; shift
    elif [ "$1" == "--verbose" ]; then
        verbose=1
        shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$dumpsbasedir" ]; then
    echo "$0: missing argument --dumpsbasedir"
    usage && exit 1
elif [ -z "$locksbasedir" ]; then
    echo "$0: missing argument --locksbasedir"
    usage && exit 1
fi

############
# create an array of all locked wikis together with their
# respective lockfiles
# sure we could glob all the subdirs I guess, but in large
# sites with tens of thousands of wikis, that would suck
#
cd "$locksbasedir" || { echo "failed to cd to $locksbasedir" && exit 1; }
wikis=$( ls -d *wik* )
locked_wikis=()
lock_files=()
for wikiname in $wikis; do
    ls "$wikiname"/lock* > /dev/null 2>&1 || continue
    locked_wikis+=( "$wikiname" )
    # if something went wrong, there could be more than one lockfile; in this case,
    # use the most recent one
    thisfile=$( ls -t "${wikiname}"/lock* 2>/dev/null | head -1 )
    lock_files+=( "${locksbasedir}/${thisfile}" )
done

############
# for each wiki that was locked, get the timestamp of the lockfile,
# compare it to the timestamp of any in progress dump files
# of any dump date, and whine if the difference is too great
#

cd "$dumpsbasedir" || { echo "failed to cd to $dumpsbasedir" && exit 1; }
for index in "${!locked_wikis[@]}"; do
    wikiname=${locked_wikis[$index]}
    lock_ts=$( /usr/bin/stat -c %Y "${lock_files[$index]}" 2>/dev/null )
    # lock file could have disappeared, so no stat
    if [ -z "$lock_ts" ]; then
        continue
    fi
    # get the date from the lockfile name
    locked_date=$( /usr/bin/mawk -F_ '{ print $NF }'<<<"${lock_files[$index]}" )
    inprog=$( ls "${wikiname}/${locked_date}/"*inprog 2>/dev/null )
    for filename in $inprog; do
	filename_ts=$( /usr/bin/stat -c %Y "$filename" 2>/dev/null)
	# dump in progress file could have disappeared, so no stat
        if [ -z "$filename_ts" ]; then
            continue
        fi
	if [ ! -z "$verbose" ]; then
            DIFF=$(( lock_ts - filename_ts ))
	    # note this could be negative if something is weird. we don't care.
            echo "INFO: $wikiname has file ${filename} with age diff ${DIFF} from lockfile (${filename_ts} vs ${lock_ts})"
        fi
        if [ $(( filename_ts + AGE_DIFFERENCE )) -lt "${lock_ts}" ]; then
            echo "PROBLEM: $wikiname has file ${filename} at least ${AGE_DIFF_HOURS} hours older than lock"
        fi
    done
done
