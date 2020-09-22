#!/bin/bash
#############################################################
# This file is maintained by puppet!
# puppet:///modules/snapshot/cron/wikibase/wikidatajson_functions.sh
#############################################################
# function used by wikibase json dumps, customized for wikidata

setDumpNameToMinSize() {
    dumpNameToMinSize=(["all"]=`expr 58000000000 / $shards` ["lexemes"]=`expr 100000000 / $shards`)
}

setDcatConfig() {
    dcatConfig=""
}
