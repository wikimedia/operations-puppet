#!/usr/bin/env bash
# Change the replica count for an index to 1
#
# Defaults to deleting the index on the local elasticsearch cluster that is 31
# days old. If run once a day, this will effectively limit our logstash log
# retention to 30 days.
#
# Attempting to delete an index that is not present on the cluster is not
# considered to be an error.

set -e

ES_HOST=${1:-http://localhost:9200}
ES_INDEX=${2:-logstash-$(date -d '-21days' +%Y.%m.%d)}

CURL_BODY=/tmp/curl-body-$$.out
CURL_HEADERS=/tmp/curl-headers-$$.out

function runCurl() {
  /usr/bin/curl --silent --show-error --write-out '%{http_code}' \
    --output "${CURL_BODY}" --dump-header "${CURL_HEADERS}" \
    "$@" | grep -E '^(2|404)' >/dev/null 2>&1
}

function cleanUp() {
    rm "${CURL_HEADERS}"
    rm "${CURL_BODY}"
}

function die() {
    echo "$*" 1>&2
    echo 1>&2
    cat "${CURL_HEADERS}" 1>&2
    cat "${CURL_BODY}" 1>&2

    cleanUp
    exit 1
}

runCurl -XPUT "${ES_HOST}/${ES_INDEX}/_settings" \
    -d '{ "index":{ "number_of_replicas": 1 } }' ||
die "Failed to decrease replica count for ${ES_HOST}/${ES_INDEX}"

cleanUp
exit
