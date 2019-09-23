#!/bin/bash
# This script loads latest categories daily dump into current namespace
. /usr/local/bin/cronUtils.sh

echo "$(date --iso-8601=seconds) starting categories daily load"

# Drop old diffs
rm -f ${DATA_DIR}/*-daily.sparql.gz
rm -f ${DATA_DIR}/dumps/*-daily.sparql.gz
# Load the data
cd ${DEPLOY_DIR}
bash forAllCategoryWikis.sh loadCategoryDaily.sh

echo "$(date --iso-8601=seconds) categories daily load done"
