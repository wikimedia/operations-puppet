#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/wikidatardf_functions.sh
#############################################################
# function used by wikibase rdf dumps, customized for wikidata

usage() {
    echo -e "Usage: $0 wikidata [--continue] all|truthy|lexemes ttl|nt [nt|ttl]\n"
    echo -e "\t--continue\tAttempt to continue a previous dump run."
    echo -e "\tall|truthy|lexemes\tType of dump to produce."
    echo -e "\tttl|nt\t\tOutput format."
    echo -e "\t[nt|ttl]\t\tOutput format for extra dump, converted from above (optional)."

    exit 1
}

setProjectName() {
    projectName="wikidata"
}

setEntityType() {
    if [[ "$dumpName" == "lexemes" ]]; then
	entityTypes="--entity-type lexeme"
    else
	entityTypes="--entity-type item --entity-type property"
    fi
}

setDumpFlavor() {
    declare -A dumpNameToFlavor
    dumpNameToFlavor=(["all"]="full-dump" ["truthy"]="truthy-dump" ["lexemes"]="full-dump")

    dumpFlavor=${dumpNameToFlavor[$dumpName]}
    if [ -z "$dumpFlavor" ]; then
	echo "Unknown dump name: $dumpName"
	exit 1
    fi
}

setFilename() {
    filename=wikidata-$today-$dumpName-BETA
}

setDumpNameToMinSize() {
    dumpNameToMinSize=(["all"]=`expr 56000000000 / $shards` ["truthy"]=`expr 30000000000 / $shards` ["lexemes"]=`expr 9000000 / $shards`)
}

setDcatConfig() {
    dcatConfig="/usr/local/etc/dcat_wikidata_config.json"
}
