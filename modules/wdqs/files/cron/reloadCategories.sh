#!/bin/bash
set -e
# This script is reloading categories into a new namespace
# NOTE: This should be run under user that has rights to
# sudo systemctl reload nginx
. /usr/local/bin/cronUtils.sh
ENDPOINT=${CATEGORY_ENDPOINT:-"http://localhost:9999"}

echo "$(date --iso-8601=seconds) starting categories reload"

newNamespace="categories${today}"
# Drop old dumps
rm -f ${DATA_DIR}/*-categories.ttl.gz
rm -f ${DATA_DIR}/dumps/*-categories.ttl.gz
cd ${DEPLOY_DIR}
# Create new namespace
bash createNamespace.sh ${newNamespace} $ENDPOINT || exit 1
# Load the data
echo "loading categories in ${newNamespace}"
bash forAllCategoryWikis.sh loadCategoryDump.sh $newNamespace
replaceNamespace categories ${newNamespace}

echo "$(date --iso-8601=seconds) categories reload done"
