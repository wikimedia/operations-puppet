#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Cron helper functions

deploy_name=$1

if [ -r /etc/$deploy_name/vars.sh ]; then
  . /etc/$deploy_name/vars.sh
fi

if [ -r /etc/$deploy_name/gui_vars.sh ]; then
  . /etc/$deploy_name/gui_vars.sh
fi

if [ -r /etc/default/categories-endpoint ]; then
  . /etc/default/categories-endpoint
fi

if [ -z "${DATA_DIR}" -o -z "${LOG_DIR}" -o -z "${DEPLOY_DIR}" ]; then
	echo "Variables not set up right!"
	exit 1
fi

NAMESPACE_URL="/bigdata/namespace/"
DUMPS_DIR="${DATA_DIR}/dumps"
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
	local endpoint=$3
	local oldNamespace=$(cat $ALIAS_FILE | grep $mainName | cut -d' ' -f2 | cut -d ';' -f1)
	if [ "${oldNamespace}" = "${currentAlias}" ]; then
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
	  if [ "$(curl -sLI -o /dev/null --fail --write-out "%{http_code}" "${endpoint}${NAMESPACE_URL}${oldNamespace}/sparql")" -eq "200" ]; then
		  # Drop old namespace
		  echo "Old namespace ${oldNamespace} still present in Blazegraph, deleting it"
		  curl -s -X DELETE "${endpoint}${NAMESPACE_URL}${oldNamespace}" && \
		  echo "Deleted ${oldNamespace}" || \
		  echo "Failed to delete ${oldNamespace}"
	  else
	    echo "Namespace ${oldNamespace} is in the alias file, but does not appear to be present in Blazegraph."
	  fi
	fi
}
