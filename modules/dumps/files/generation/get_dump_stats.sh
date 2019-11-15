#!/bin/bash
#############################################################
# This file is managed by puppet!
# modules/dumps/generation/get_dump_stats.sh
#############################################################

# Note that this script should run a couple days after the
# full monthly dump run completes for all wikis. Currently,
# any time from the 20th til the end of the month would be ok.

get_wiki_stats() {
    wiki=$1
    user=$2
    password=$3

    date=$( cd $wiki 2>/dev/null; ls -d 2*01 2>/dev/null | tail -1 )
    if [ -z "$date" ]; then
        echo "Failed to get date of the last full dump run for $wiki."
        currentpages="No info available (no full run date found)"
	currentall="No info available (no full run date found)"
	fullhistory="No info available (no full run date found)"
	date="--"
	return
    fi

    cd "${dumpsbasedir}/${wiki}/${date}"
    if [ -e "${wiki}-${date}-pages-articles.xml.bz2" ]; then
	currentpages=$( bzcat "${wiki}-${date}-pages-articles.xml.bz2" | wc -c )
    else
        currentpages="No info available (no files found)"
    fi
    if [ -e "${wiki}-${date}-pages-meta-current.xml.bz2" ]; then
	currentall=$( bzcat "${wiki}-${date}-pages-meta-current.xml.bz2" | wc -c )
    else
	currentall="No info available (no files found)"
    fi
    pmhcount=$( ls ${wiki}-${date}-pages-meta-history*.xml*bz2 2>/dev/null | wc -l )
    if [ $pmhcount -gt 0 ]; then
	fullhistory=$( bzcat ${wiki}-${date}-pages-meta-history*.xml*bz2 | wc -c )
    else
	fullhistory="No info available (no files found)"
    fi
    cd "${dumpsbasedir}"
}

get_stats_text() {
    cat <<EOF
---------------------
Stats for ${wiki} on date ${date}

Total size of page content dump files for articles, current content only:
${currentpages}

Total size of page content dump files for all pages, current content only:
${currentall}

Total size of page content dump files for all pages, all revisions:
${fullhistory}
EOF

}

usage() {
    cat<<EOF
Usage: $0 dumpsbasedir <path>

  --dumpsbasedir   path to root of xml/sql dumps dir where per-wiki dump output files may be found
Example:

 $0 --dumpsbasedir /data/xmldatadumps/public
EOF
    exit 1
}

###############
# main
###############

dumpsbasedir=""
verbose=""
sender_address=""

while [ $# -gt 0 ]; do
    if [ $1 == "--dumpsbasedir" ]; then
        dumpsbasedir="$2"
        shift; shift
    elif [ $1 == "--sender_address" ]; then
        sender_address="$2"
        shift; shift
    else
        echo "$0: Unknown option $1" >& 2
        usage
    fi
done

if [ -z "$dumpsbasedir" ]; then
    echo "$0: missing argument --dumpsbasedir"
    usage && exit 1
elif [ -z "$sender_address" ]; then
    echo "$0: missing argument --sender_address"
    usage && exit 1
fi

cd "$dumpsbasedir"
allsubdirs=$( find . -mindepth 1 -maxdepth 1 -name '*wik*' -type d | sed -e 's|\./||g;' )
allsubdirs_array=( $allsubdirs )
emptysubdirs=$( find . -mindepth 1 -maxdepth 1 -name '*wik*' -type d -empty | sed -e 's|\./||g;' )
emptysubdirs_array=( $emptysubdirs )
totaldumped=$(( ${#allsubdirs_array[@]} - ${#emptysubdirs_array[@]} ))

if [ -n "$emptysubdirs" ]; then
    for target in "${emptysubdirs_array[@]}"; do
	for i in "${!allsubdirs_array[@]}"; do
	    if [[ ${allsubdirs_array[$i]} = "${emptysubdirs_array[$target]}" ]]; then
		unset allsubdirs_array[$i]
	    fi
	done
    done
    for i in "${!allsubdirs_array[@]}"; do
	new_allsubdirs_array+=( "${allsubdirs_array[$i]}" )
    done
    allsubdirs_array=("${new_allsubdirs_array[@]}")
    unset new_allsubdirs_array
fi

# choose random wiki not enwiki
wikirandom_index=$(( $RANDOM % $totaldumped ))
wikirandom=${allsubdirs_array[$wikirandom_index]}
if [ "$wikirandom" == "enwiki" ]; then
    # try again, we'll get some other wiki this time... surely?
    wikirandom_index=$( $RANDOM % $totaldumped )
    wikirandom=${allsubdirs_array[$wikirandom]}
fi

for wiki in "$wikirandom" "enwiki"; do
    get_wiki_stats $wiki
    wikistatstext=$( get_stats_text )
    emailbody="${emailbody}\

${wikistatstext}"
done

###############
# send email
###############
if [ -e '/usr/bin/s-nail' ]; then
    MAILCMD='/usr/bin/s-nail'
else
    MAILCMD='/usr/bin/mail'
fi
cat <<EOF | $MAILCMD -r "${sender_address}" -s "XML Dumps FAQ monthly update" "xmldatadumps-l@lists.wikimedia.org"

Greetings XML Dump users and contributors!

This is your automatic monthly Dumps FAQ update email.  This update
contains figures for the ${date} full revision history content run.

We are currently dumping ${totaldumped} projects in total.

${emailbody}
---------------------


Sincerely,

Your friendly Wikimedia Dump Info Collector
EOF

