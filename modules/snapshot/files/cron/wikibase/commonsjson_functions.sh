#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/commonsjson_functions.sh
#############################################################
# function used by wikibase json dumps, customized for Commons

setDumpNameToMinSize() {
    dumpNameToMinSize=(["all"]=`expr 1000 / $shards`)
}

setDcatConfig() {
	# TODO: add DCAT info
    dcatConfig=""
}
