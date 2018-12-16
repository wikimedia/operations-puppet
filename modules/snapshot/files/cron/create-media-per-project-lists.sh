#!/bin/bash

#############################################################
# This file is maintained by puppet!
# modules/snapshot/cron/create-media-per-project-lists.sh
#############################################################

source /usr/local/etc/set_dump_dirs.sh

DATE=`/bin/date '+%Y%m%d'`
outputdir="${cronsdir}/imageinfo/$DATE"
configfile="${confsdir}/wikidump.conf.dumps:media"
errors=0

cd "$repodir"

python3 "${repodir}/onallwikis.py" --outdir "$outputdir" \
       --config "$configfile" --nooverwrite \
       --query "'select img_name, img_timestamp from image;'" \
       --filenameformat "{w}-{d}-local-wikiqueries.gz"
if [ $? -ne 0 ]; then
    echo "failed sql dump of image tables"
    errors=1
fi

# determine which wiki has the global image links table and set as base wiki for the run
globalusagelist="${dblistsdir}/globalusage.dblist"
basewiki=`cat "$globalusagelist"`

python3 "${repodir}/onallwikis.py" --outdir "$outputdir" \
       --base "$basewiki" \
       --config "$configfile" --nooverwrite \
       --query "'select gil_to from globalimagelinks where gil_wiki= \"{w}\";'" \
       --filenameformat "{w}-{d}-remote-wikiqueries.gz"

if [ $? -ne 0 ]; then
    echo "failed sql dump of globalimagelink tables"
    errors=1
fi

exit $errors
