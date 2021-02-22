#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/commonsrdf_functions.sh
#############################################################
# function used by wikibase rdf dumps, customized for Commons

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

setDcatConfig() {
	# TODO: add DCAT info
    dcatConfig=""
}
