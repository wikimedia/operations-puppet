#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/commonsrdf_functions.sh
#############################################################
# function used by wikibase rdf dumps, customized for Commons

usage() {
    echo -e "Usage: $0 commons [--continue] mediainfo ttl|nt [nt|ttl]\n"
    echo -e "\t--continue\tAttempt to continue a previous dump run."
    echo -e "\tttl|nt\t\tOutput format."
    echo -e "\t[nt|ttl]\t\tOutput format for extra dump, converted from above (optional)."

    exit 1
}

setProjectName() {
    projectName="commons"
}

setEntityType() {
	entityTypes="--entity-type mediainfo --ignore-missing"
}

setDumpFlavor() {
	dumpFlavor="full-dump"
}

setFilename() {
    filename=commons-$today-$dumpName
}

setDumpNameToMinSize() {
	# TODO: figure out what number makes sense here
    dumpNameToMinSize=(["mediainfo"]=1000)
}

setDcatConfig() {
	# TODO: add DCAT info
}
