#!/bin/bash

sourcehost="download.kiwix.org"
destroot="/data/xmldatadumps/public/other"

bwlimit="--bwlimit=40000"

do_rsync (){
    srcpath=$1
    destpath=$2

    running=`pgrep -u root -f -x "/usr/bin/rsync -rlptqgo $bwlimit ${sourcehost}::${srcpath} ${destroot}/${destpath}"`
    if [ -z "$running" ]; then
        /usr/bin/rsync -rlptqgo "$bwlimit" "${sourcehost}::${srcpath}" "${destroot}/${destpath}"
    fi
}

do_rsync "download.kiwix.org/zim/wikipedia/" "kiwix/zim/wikipedia/"
