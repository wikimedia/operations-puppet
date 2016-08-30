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


running=`pgrep -u root -f   "python /usr/local/bin/wmfdumpsmirror.py --dest_hostname labstore1003.eqiad.wmnet"`
if [ -z "$running" ]; then
    python /usr/local/bin/wmfdumpsmirror.py --dest_hostname labstore1003.eqiad.wmnet --sourcedir /data/xmldatadumps/public --destdir dumps/public --filesperjob 50 --sizeperjob 5G --workercount 1 --rsynclist rsync-filelist-last-3-good.txt.rsync --rsyncargs -rlptqgo,--bwlimit=50000
fi

# fixme need to ensure ${desthost}::dumps/public/wikidatawiki/entities/ exists

#copy from our dumps "other" directory to the labs host copy of dumps
do_rsync "incr" ""
do_rsync "wikibase/wikidatawiki/" "public/wikidatawiki/entities/"
do_rsync "pageviews" ""
