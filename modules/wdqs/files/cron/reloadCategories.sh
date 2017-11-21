#!/bin/bash
# This script is reloading categories into a new namespace
# NOTE: This should be run under user that has rights to
# sudo systemctl reload nginx
if [ -r /etc/wdqs/vars.sh ]; then
  . /etc/wdqs/vars.sh
fi

if [ -r /etc/wdqs/gui_vars.sh ]; then
  . /etc/wdqs/gui_vars.sh
fi

today=$(date -u +'%Y%m%d')
newNamespace="categories${today}"
# Drop old dumps
rm -f "${DATA_DIR}/*-categories.ttl.gz"
cd $DEPLOY_DIR
bash createNamespace.sh $newNamespace || exit 1
# Load the data
bash forAllCategoryWikis.sh loadCategoryDump.sh $newNamespace >> "${LOG_DIR}/${newNamespace}.log"
# Get old namespace
oldNamespace=$(cat $ALIAS_FILE | grep categories | cut -d' ' -f2)
# Switch the map
# NOTE: right now it overrides the map. If we reuse it for other purposes, this needs to be made smarter.
echo "categories ${newNamespace}" > $ALIAS_FILE
# Bump nginx to reload config
sudo systemctl reload nginx
if [ -n "${oldNamespace}" ]; then
	# Drop old namespace
	curl -s -X DELETE "http://localhost:9999/bigdata/namespace/${oldNamespace}"
fi
