#!/usr/bin/env bash
# Clear Elasticsearch cache
#
# Defaults to clearing caches for all logstash-* indices on the localhost

set -e

ES_HOST=${1:-localhost:9200}
ES_INDEX=${2:-logstash-*}

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

runCurl -XPOST "${ES_HOST}/${ES_INDEX}/_cache/clear" ||
die "Failed to clear cache for ${ES_HOST}/${ES_INDEX}"

cleanUp
exit
