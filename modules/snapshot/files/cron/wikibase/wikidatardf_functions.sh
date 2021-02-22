#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/wikidatardf_functions.sh
#############################################################
# function used by wikibase rdf dumps, customized for wikidata

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

setDcatConfig() {
    dcatConfig="/usr/local/etc/dcat_wikidata_config.json"
}
