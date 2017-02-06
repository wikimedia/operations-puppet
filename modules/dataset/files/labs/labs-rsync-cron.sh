#!/bin/bash
desthost="labstore1003.eqiad.wmnet"
otherdir="/data/xmldatadumps/public/other"
bwlimit="--bwlimit=50000"

do_rsync (){
    srcdir=$1
    destdir=$2

    running=`pgrep -u root -f -x "/usr/bin/rsync -rlptqgo $bwlimit ${otherdir}/${srcdir} ${desthost}::dumps/${destdir}"`
    if [ -z "$running" ]; then
        /usr/bin/rsync -rlptqgo "$bwlimit" "${otherdir}/${srcdir}" "${desthost}::dumps/${destdir}"
    fi
}


running=`pgrep -u root -f   "rsync -rlptqgo --bwlimit=50000 /data/xmldatadumps/public ${desthost}::dumps/public"`
if [ -z "$running" ]; then
    rsync -rlptqgo --bwlimit=50000 /data/xmldatadumps/public/ ${desthost}::dumps/public/ \
	  --include-from=/data/xmldatadumps/public/rsync-inc-last-3.txt \
	  --include='/*wik*/' \
	  --exclude='**tmp/ **temp/ **bad/ **save/ **other/ **archive/ **not/ /* /*/ /*/*/'
fi

# fixme need to ensure ${desthost}::dumps/public/wikidatawiki/entities/ exists

#copy from our dumps "other" directory to the labs host copy of dumps
do_rsync "incr" ""
do_rsync "wikibase/wikidatawiki/" "public/wikidatawiki/entities/"
do_rsync "pageviews" ""
