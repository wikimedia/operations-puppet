#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# This script is reloading DCAT-AP data from Wikidata
# NOTE: This should be run under user that has rights to
# sudo systemctl reload nginx
. /usr/local/bin/cronUtils.sh $1

DCAT_SOURCE=${DCAT_SOURCE:-"https://dumps.wikimedia.org/wikidatawiki/entities/dcatap.rdf"}

endpoint=http://localhost:9990
newNamespace="dcatap${today}"
# Drop old dumps
rm -f ${DATA_DIR}/dcatap-*.rdf
cd $DEPLOY_DIR
# Create new NS
bash createNamespace.sh $newNamespace $endpoint || exit 1
# Load the data
FILENAME=dcatap-${today}.rdf
loadFileIntoBlazegraph $DCAT_SOURCE $FILENAME "$endpoint${NAMESPACE_URL}${newNamespace}/sparql"
replaceNamespace dcatap $newNamespace $endpoint
