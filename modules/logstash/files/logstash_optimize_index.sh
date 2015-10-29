#!/usr/bin/env bash
# Optimize an elasticsearch index
#
# Defaults to optimizing yesterday's index on the local elasticsearch cluster.

set -e

ES_HOST=${1:-http://localhost:9200}
ES_INDEX=${2:-logstash-$(date -d '-1day' +%Y.%m.%d)}

CURL_BODY=/tmp/curl-body-$$.out
CURL_HEADERS=/tmp/curl-headers-$$.out

function runCurl() {
  /usr/bin/curl --silent --show-error --write-out '%{http_code}' \
    --output "${CURL_BODY}" --dump-header "${CURL_HEADERS}" \
    "$@" | grep '^2' >/dev/null 2>&1
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

runCurl -XGET "${ES_HOST}/${ES_INDEX}/_segments?pretty=true" ||
die "Failed to query segments for ${ES_HOST}/${ES_INDEX}"

SEGMENTS=$(grep num_search_segments "${CURL_BODY}"|cut -d: -f2|tr -d ' ,')

if [[ $SEGMENTS > 1 ]]; then
    runCurl -XPOST "${ES_HOST}/${ES_INDEX}/_optimize?max_num_segments=1" ||
    die "Failed to optimize ${ES_HOST}/${ES_INDEX}"
fi

runCurl -XPUT "${ES_HOST}/${ES_INDEX}/_settings" \
    -d '{"index.blocks.write":true}' ||
die "Failed to change settings for ${ES_HOST}/${ES_INDEX}"

runCurl -XPOST "${ES_HOST}/${ES_INDEX}/_flush/synced" ||
die "Failed to force a synced flush for ${ES_HOST}/${ES_INDEX}"

cleanUp
exit
