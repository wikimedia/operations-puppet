#!/bin/bash

# NOTE: this file is maintained in puppet

# rsync XML dumps and other public datasets between the various dataset servers,
# allowing for the possibility that dumps may be produced on any or all of them
# for different sets of wikis

# this script takes one possible argument: "dryrun" in which case it prints what it would
# do instead of actually doing the rsyncs

if [ "$1" == "dryrun" ]; then
    DRYRUN=1
else
    DRYRUN=0
fi

RSYNCBW="40000"


HOST=`/bin/hostname`

RSYNCCMD='/usr/bin/rsync'
RSYNCARGS=( '-q' "--bwlimit=$RSYNCBW" '-a' '--delete' )
EXCLUDES=( '--exclude=wikidump_*' '--exclude=md5temp.*' )
RSYNCSRC='/data/xmldatadumps/public/'

MAILCMD='/usr/bin/mail'
MAILARGS=( '-E' '-s' "DUMPS RSYNC $HOST" 'ops-dumps@wikimedia.org' )

SERVERS=( 'dataset2' 'dataset1001' )
# remove self from the list
for ((i=0; i<"${#SERVERS[*]}"; i++)); do
    if [ "${SERVERS[$i]}" == "$HOST" ]; then
	unset "SERVERS[$i]"
    fi
done

do_rsyncs () {
    for s in "${SERVERS[@]}"; do
	running=`pgrep -u root -f "$s::data/xmldatadumps/public/"`
	if [ ! -z "$running" ]; then
	    exit 0
	fi
	RSYNCDEST="$s::data/xmldatadumps/public/"
	if [ $DRYRUN -eq 0 ]; then
	    $RSYNCCMD "${RSYNCARGS[@]}" "${EXCLUDES[@]}" "${EXTRAARGS[@]}" "${RSYNCSRC}" "${RSYNCDEST}" 2>&1 | $MAILCMD "${MAILARGS[@]}"
	else
	    echo -n $RSYNCCMD "${RSYNCARGS[@]}" "${EXCLUDES[@]}" "${EXTRAARGS[@]}" "${RSYNCSRC}" "${RSYNCDEST}"
	    echo '|' "$MAILCMD" "${MAILARGS[@]}"
	fi
    done
}

case "$HOST" in
    'dataset2' )
	# directories for which this host produces dumps or for which new data is uploaded to this host
	DIRS=( '/other/' ) # must have leading/trailing slash
	DIRARGS=( "${DIRS[@]/#/--include=}" )
	EXTRAARGS=( "${DIRARGS[@]}" "${DIRARGS[@]/%/**}" '--exclude=*' )
	do_rsyncs
	;;
    'dataset1001' )
	# all dumps are produced on this host and all new data uploaded to except for these dirs
	DIRS=( '/other/' ) # must have leading/trailing slash
	EXTRAARGS=( "${DIRS[@]/#/--exclude=}" )
	do_rsyncs
	;;
    * )
    echo "No rsync stanza available for $HOST"
	;;
esac
