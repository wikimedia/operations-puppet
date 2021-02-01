#!/bin/bash

#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/create-media-per-project-lists.sh
#############################################################

source /usr/local/etc/set_dump_dirs.sh

usage() {
    echo "Usage: $0 [--config <pathtofile>] [--dryrun]" >& 2
    echo >& 2
    echo "  --config   path to configuration file for dump generation" >& 2
    echo "             (default value: ${confsdir}/wikidump.conf.dumps:media" >& 2
    echo "  --dryrun   don't run dump, show what would have been done" >& 2
    exit 1
}

configfile="${confsdir}/wikidump.conf.dumps:media"
dryrun="false"

while [ $# -gt 0 ]; do
    if [ $1 == "--config" ]; then
        configfile="$2"
        shift; shift
    elif [ $1 == "--dryrun" ]; then
        dryrun="true"
        shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

DATE=`/bin/date '+%Y%m%d'`
outputdir="${cronsdir}/imageinfo/$DATE"
errors=0

cd "$repodir"

if [ "$dryrun" == "true" ]; then
    echo python3 "${repodir}/onallwikis.py" --outdir "$outputdir" --config "$configfile" --nooverwrite \
	 --query "'select img_name, img_timestamp from image;'" --filenameformat "{w}-{d}-local-wikiqueries.gz"
else
    python3 "${repodir}/onallwikis.py" --outdir "$outputdir" --config "$configfile" --nooverwrite \
       --query "'select img_name, img_timestamp from image;'" --filenameformat "{w}-{d}-local-wikiqueries.gz"
fi

if [ $? -ne 0 ]; then
    echo "failed sql dump of image tables"
    errors=1
fi

# determine which wiki has the global image links table and set as base wiki for the run
globalusagelist="${dblistsdir}/globalusage.dblist"
basewiki=`cat "$globalusagelist"`

if [ "$dryrun" == "true" ]; then
    echo python3 "${repodir}/onallwikis.py" --outdir "$outputdir" --base "$basewiki" --config "$configfile" \
       --nooverwrite --query "'select gil_to from globalimagelinks where gil_wiki= \"{w}\";'" --filenameformat "{w}-{d}-remote-wikiqueries.gz"
else
    python3 "${repodir}/onallwikis.py" --outdir "$outputdir" --base "$basewiki" --config "$configfile" \
       --nooverwrite --query "'select gil_to from globalimagelinks where gil_wiki= \"{w}\";'" --filenameformat "{w}-{d}-remote-wikiqueries.gz"
fi

if [ $? -ne 0 ]; then
    echo "failed sql dump of globalimagelink tables"
    errors=1
fi

exit $errors
