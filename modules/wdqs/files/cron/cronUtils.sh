#!/bin/bash
# Cron helper functions
if [ -r /etc/wdqs/vars.sh ]; then
  . /etc/wdqs/vars.sh
fi

if [ -r /etc/wdqs/gui_vars.sh ]; then
  . /etc/wdqs/gui_vars.sh
fi

if [ -z "${DATA_DIR}" -o -z "${LOG_DIR}" -o -z "${DEPLOY_DIR}" ]; then
	echo "Variables not set up right!"
	exit 1
fi

HOST=${CATEGORY_ENDPOINT:-"http://localhost:9999"}
NAMESPACE_URL="/bigdata/namespace/"
today=$(date -u +'%Y%m%d')

function loadFileIntoBlazegraph {
	# source URL
	local URL=$1
	# local filename (will be in DATA_DIR)
	local fileName=$2
	local sparqlEndpoint=$3
	curl -s -f -XGET $URL -o ${DATA_DIR}/${fileName}
	if [ ! -s ${DATA_DIR}/${fileName} ]; then
		echo "Could not download $URL into ${fileName}"
		exit 1
	fi	
	curl -s -XPOST --data-binary update="LOAD <file://$DATA_DIR/$FILENAME>" $sparqlEndpoint
}

# NOTE: This should be run under user that has rights to
# sudo systemctl reload nginx
function replaceNamespace {
	local mainName=$1
	local currentAlias=$2
	local oldNamespace=$(cat $ALIAS_FILE | grep $mainName | cut -d' ' -f2 | cut -d ';' -f1)
	if [ "${oldNamespace}" = ${currentAlias} ]; then
		# nothing to do
		return
	fi
	if [ -n "${oldNamespace}" ]; then
		sed -i "/${mainName}/c ${mainName} ${currentAlias};" $ALIAS_FILE
	else
		echo "${mainName} ${currentAlias};" >> $ALIAS_FILE
	fi
	# Bump nginx to reload config
	sudo systemctl reload nginx
	if [ -n "${oldNamespace}" ]; then
		# Drop old namespace
		curl -s -X DELETE "${HOST}${NAMESPACE_URL}${oldNamespace}"
	fi
}
