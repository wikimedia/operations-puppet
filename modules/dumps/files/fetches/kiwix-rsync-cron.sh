#!/bin/bash
######################################
# This file is managed by puppet!
#  puppet:///modules/dumps/fetches/kiwix-rsync-cron.sh
######################################

set -o errexit
set -o nounset

SOURCEHOST="master.download.kiwix.org"
BWLIMIT="--bwlimit=40000"

do_rsync(){
    local srcpath=$1
    local destpath=$2
    local destroot=$3
    local destdir="${destroot}/${destpath}"

    local running=$(
        /usr/bin/pgrep -f -x "/usr/bin/rsync -rlptq $BWLIMIT ${SOURCEHOST}::${srcpath} ${destdir}"
    )
    if [[ "$running" != "" ]]; then
        echo "Already running, skipping: $running"
        return 0
    fi

    [[ -e "$destdir" ]] || mkdir -p "$destdir"

    # filter out messages of the type
    #   file has vanished: "/zim/wikipedia/.wikipedia_tg_all_nopic_2016-05.zim.TQH5Zv" (in download.kiwix.org)
    #   rsync warning: some files vanished before they could be transferred (code 24) at main.c(1655) [generator=3.1.1]
    # cat makes the pipeline command never fail
    /usr/bin/rsync \
        -rlptq \
        --delete \
        "$BWLIMIT" \
        "${SOURCEHOST}::${srcpath}" \
        "${destroot}/${destpath}" \
    2>&1 \
    | grep -v 'vanished' \
    | cat
    # now we check the return code of rsync
    local rsync_rc=${PIPESTATUS[0]}
    if [[ "$rsync_rc" != "0" ]]; then
        echo "Error while running rsync, check the logs..."
        return $rsync_rc
    fi
    return 0
}

if [[ "$1" == "" ]]; then
    echo "Usage: $0 dest_base_dir"
    exit 1
fi

do_rsync "download.kiwix.org/zim/wikipedia/" "kiwix/zim/wikipedia/" "$1"
