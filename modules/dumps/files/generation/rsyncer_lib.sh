#!/bin/bash

##############################
# This file is managed by puppet!
# puppet:///modules/dumps/generation/rsyncer_lib.sh
##############################

# This is a library of routines etc that should be sourced
# by dump rsyncer scripts. Those scripts might
# puull xml/sql dumps or "misc" dumps or dump status files
# from primary to the secondary, push from the secondary to
# public facing hosts, and push from the primary to all
# other hosts, as desired.

# set up some global arg vars so we can reuse them
TEMPVAR='**bad/ **save/ **not/ **temp/ **tmp/ *.inprog *.html *.txt *.json'
# shellcheck disable=SC2086
read -ra DUMPFILES_EXCLUDES <<<$TEMPVAR
DUMPFILES_EXCLUDES=( "${DUMPFILES_EXCLUDES[@]/#/--exclude=}" )

TESTRUN_OUTPUT="/tmp/dumpsrsync_test.txt"

init_rlib() {
    rl_istest="$1"
    rl_show="$2"
    RSYNC_DRYRUN_ARGS=( "--dry-run" "--itemize-changes" )
}

get_comma_sep() {
    local sourcevar="$1"
    IFS_SAVE=$IFS
    IFS=','
    # shellcheck disable=SC2086
    read -ra tempfields <<<$sourcevar
    IFS=$IFS_SAVE
    echo "${tempfields[@]}"
}

set_rsync_stdargs() {
    local bandwidth="$1"
    RSYNC_STD_ARGS=( "--contimeout=600"  "--timeout=600" "--bwlimit=$bandwidth" )
}

make_statusfiles_tarball() {
    local localdir="$1"

    # make tarball of all xml/sql dumps status and html files
    local tarballpath="${localdir}/dumpstatusfiles.tar"
    local tarballpathgz="${tarballpath}.gz"

    # Only tarball up the status files from the latest run; even if it's
    # only partially done or for some wikis it's not started, that's fine.
    # Files from the previous run will have already been sent over before
    # the new run started, unless there are 0 minutes between end of
    # one dump run across all wikis and start of the next (in which case
    #  we are cutting things WAY too close with the runs)
    local latestwiki=$( cd "$localdir"; ls -td *wik* | head -1 )

    # dirname is YYYYMMDD, i.e. 8 digits. ignore all other directories.
    local latestrun=$( cd "${localdir}/${latestwiki}"; ls -d [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] | sort | tail -1 )

    if [ -z "$rl_show" ]; then
	# top-level index files first
	( cd "$localdir"; /bin/tar cfp "$tarballpath" ./*html ./*json )

	# files from latest run
	if [ -n "$latestrun" ]; then
            # add per-wiki files next: ( cd /data/xmldatadumps/incoming; /usr/bin/find . -maxdepth 3 -regextype sed -regex ".*/20171120/.*\(json\|html\|txt\)" )
            ( cd "$localdir"; /usr/bin/find "." -maxdepth 3 -regextype sed -regex ".*/${latestrun}/.*\\.\\(json\\|html\\|txt\\)" | /usr/bin/xargs -s 1048576 /bin/tar rfp "$tarballpath" )
	    # add txt files from 'latest' directory
	    ( cd "$localdir"; /usr/bin/find "." -maxdepth 3 -regextype sed -regex ".*/latest/.*\\.txt" | /usr/bin/xargs -s 1048576 /bin/tar rfp "$tarballpath" )
            # if no files found, there will be no tarball created either
	fi
	/bin/gzip -S '.tmp' "$tarballpath"
	mv "${tarballpath}.tmp" "$tarballpathgz"
	if [ "$rl_istest" ]; then
	    /bin/zcat "$tarballpathgz" | /bin/tar tvf - >> "$TESTRUN_OUTPUT"
	fi
    fi

    echo "$tarballpathgz"
}

push_tarball() {
    local tarballfullpath="$1"
    local remote="$2"

    RSYNC_TARBALL_ARGS=( "$tarballfullpath"  "$remote" )

    # send statusfiles tarball over last, remote can unpack it when it notices the arrival
    # this way, content of status and html files always reflects dump output already
    # made available via rsync
    if [ -f "$tarballfullpath" ]; then
        if [ "$rl_show" ]; then
            echo /usr/bin/rsync -pgo  "${RSYNC_STD_ARGS[@]}" "${RSYNC_TARBALL_ARGS[@]}"
	elif [ "$rl_istest" ]; then
            /usr/bin/rsync "${RSYNC_DRYRUN_ARGS[@]}" -pgo  "${RSYNC_STD_ARGS[@]}" "${RSYNC_TARBALL_ARGS[@]}" >> "$TESTRUN_OUTPUT"
        else
            /usr/bin/rsync -pgo  "${RSYNC_STD_ARGS[@]}" "${RSYNC_TARBALL_ARGS[@]}" > /dev/null 2>&1
        fi
    fi
}

push_tarball() {
    local tarballfullpath="$1"
    local remote="$2"

    RSYNC_TARBALL_ARGS=( "$tarballfullpath"  "$remote" )

    # send statusfiles tarball over last, remote can unpack it when it notices the arrival
    # this way, content of status and html files always reflects dump output already
    # made available via rsync
    if [ -f "$tarballfullpath" ]; then
        if [ "$rl_show" ]; then
            echo /usr/bin/rsync -pgo  "${RSYNC_STD_ARGS[@]}" "${RSYNC_TARBALL_ARGS[@]}"
	elif [ "$rl_istest" ]; then
            /usr/bin/rsync "${RSYNC_DRYRUN_ARGS[@]}" -pgo  "${RSYNC_STD_ARGS[@]}" "${RSYNC_TARBALL_ARGS[@]}" >> "$TESTRUN_OUTPUT"
        else
            /usr/bin/rsync -pgo  "${RSYNC_STD_ARGS[@]}" "${RSYNC_TARBALL_ARGS[@]}" > /dev/null 2>&1
        fi
    fi
}

push_dumpfiles() {
    local localdir="$1"
    local remote="$2"

    RSYNC_DUMPFILES_ARGS=( "${localdir}"/*wik* "$remote" )

    if [ "$rl_show" ]; then
	echo /usr/bin/rsync -a  "${RSYNC_STD_ARGS[@]}" "${DUMPFILES_EXCLUDES[@]}" "${RSYNC_DUMPFILES_ARGS[@]}"
    elif [ "$rl_istest" ]; then
	/usr/bin/rsync "${RSYNC_DRYRUN_ARGS[@]}" -a "${RSYNC_STD_ARGS[@]}" "${DUMPFILES_EXCLUDES[@]}" "${RSYNC_DUMPFILES_ARGS[@]}" >> "$TESTRUN_OUTPUT"
    else
	/usr/bin/rsync -a  "${RSYNC_STD_ARGS[@]}" "${DUMPFILES_EXCLUDES[@]}" "${RSYNC_DUMPFILES_ARGS[@]}" > /dev/null 2>&1
    fi
}

push_misc_dumps() {
    local localdir="$1"
    local remote="$2"

    RSYNC_MISCDUMPS_ARGS=( "${localdir}"/* "$remote" )

    # rsync of misc dumps to public-facing hosts, not necessarily to/from the same tree as the public wikis
    # these hosts must get all the contents we have available
    if [ "$rl_show" ]; then
        echo /usr/bin/rsync -a  "${RSYNC_STD_ARGS[@]}" "${RSYNC_MISCDUMPS_ARGS[@]}"
    elif [ "$rl_istest" ]; then
        /usr/bin/rsync "${RSYNC_DRYRUN_ARGS[@]}" -a  "${RSYNC_STD_ARGS[@]}" "${RSYNC_MISCDUMPS_ARGS[@]}" >> "$TESTRUN_OUTPUT"
    else
        /usr/bin/rsync -a  "${RSYNC_STD_ARGS[@]}" "${RSYNC_MISCDUMPS_ARGS[@]}" > /dev/null 2>&1
    fi
}

push_misc_subdirs() {
    local localdir="$1"
    local remote="$2"
    local subdir="$3"

    RSYNC_MISCDIRS_ARGS=( "${localdir}/${subdir}" "$remote" )

    if [ "$rl_show" ]; then
        echo /usr/bin/rsync -a "${RSYNC_STD_ARGS[@]}" "${RSYNC_MISCDIRS_ARGS[@]}"
    elif [ "$rl_istest" ]; then
	/usr/bin/rsync "${RSYNC_DRYRUN_ARGS[@]}" -a "${RSYNC_STD_ARGS[@]}" "${RSYNC_MISCDIRS_ARGS[@]}" >> "$TESTRUN_OUTPUT"
    else
        /usr/bin/rsync -a  "${RSYNC_STD_ARGS[@]}" "${RSYNC_MISCDIRS_ARGS[@]}" > /dev/null 2>&1
    fi
}
