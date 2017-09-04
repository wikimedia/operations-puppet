#!/bin/bash

#############################################################
# This file is maintained by puppet!
# modules/dumps/otherdumps/weeklies/create-media-per-project-lists.sh
#############################################################

source /usr/local/etc/dump_functions.sh

DATE=$( /bin/date '+%Y%m%d' )
outputdir="${otherdumpsdir}/imageinfo/$DATE"
configfile="${confsdir}/wikidump.conf.media"
errors=0

cd "$repodir"

/usr/bin/python "${repodir}/onallwikis.py" --outdir "$outputdir" \
       --config "$configfile" --nooverwrite \
       --query "'select img_name, img_timestamp from image;'" \
       --filenameformat "{w}-{d}-local-wikiqueries.gz"
if [ $? -ne 0 ]; then
    echo "failed sql dump of image tables"
    errors=1
fi

basewiki=commonswiki

/usr/bin/python "${repodir}/onallwikis.py" --outdir "$outputdir" \
       --base "$basewiki" \
       --config "$configfile" --nooverwrite \
       --query "'select gil_to from globalimagelinks where gil_wiki= \"{w}\";'" \
       --filenameformat "{w}-{d}-remote-wikiqueries.gz"

if [ $? -ne 0 ]; then
    echo "failed sql dump of globalimagelink tables"
    errors=1
fi

exit $errors
