#!/bin/sh -eu
set -o pipefail

DOCKER="${DOCKER:-docker}"
IMAGE_NAME=wikimedia
UTILS_DIR=$(readlink -f ../../../../utils)
CONTAINER_NAME=wikimedia_varnish_test_env
TEMP_FILE=$(mktemp -t vtcresults.XXXXXXXXXX)
PCC_PATH=/utils/pcc
# Fail early if these aren't set rather than waiting until after Docker builds
JENKINS_USERNAME="${JENKINS_USERNAME:?'Jenkins username is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
JENKINS_API_TOKEN="${JENKINS_API_TOKEN:?'Jenkins API token is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
HOST="${1:?\"Usage: $0 <hostname> <change_num_or_pcc_url> [vtc_file_glob='*']\"}"
CHANGE_ID="${2:?\"Usage: $0 <hostname> <change_num_or_pcc_url> [vtc_file_glob='*']\"}"
VTC_FILEGLOB="${3:-}"

if [ -d /tmp ]; then
    rm -f /tmp/vtcresults.last
fi

# How this works:
# * docker-run mounts $(pwd) as /wikimedia/varnish
# * run.py writes to /wikimedia/varnish/tmp/XXX
# * run.py prints "Test output saved to /wikimedia/varnish/tmp/XXX"
# * docker-run tees run.py stdout to intermediary TEMP_FILE
# * clean_up searches stdout (briefly stored in TEMP_FILE) for the tmp filename.
# * clean_up moves tmp filename over TEMP_FILE, so it stays in /tmp instead of pwd.
clean_up() {
    CONTAINER_TEMP_FILE=$(grep  -o '/wikimedia/varnish/tmp/\w*' "${TEMP_FILE}")
    if [ -n "$CONTAINER_TEMP_FILE" ]; then
        mv tmp/$(basename "$CONTAINER_TEMP_FILE") "${TEMP_FILE}"
        echo "Results copied from container to ${TEMP_FILE}"
        if [ -d /tmp ]; then
            ln -sf "$TEMP_FILE" /tmp/vtcresults.last
            echo "Results linked at /tmp/vtcresults.last for your convenience."
        fi
    fi
}

trap clean_up EXIT

$DOCKER build -q -t ${IMAGE_NAME} .
$DOCKER run -it --rm --name ${CONTAINER_NAME} \
    --env JENKINS_USERNAME="${JENKINS_USERNAME}" \
    --env JENKINS_API_TOKEN="${JENKINS_API_TOKEN}" \
    --env VARNISHTEST_CONTAINER=1 \
    --mount type=bind,source="${UTILS_DIR}",target=/utils \
    --mount type=bind,source="$(pwd)",target=/"${IMAGE_NAME}"/varnish \
    ${IMAGE_NAME} varnish/run.py "$HOST" "$CHANGE_ID" "${PCC_PATH}" "${VTC_FILEGLOB}" | tee "${TEMP_FILE}"
