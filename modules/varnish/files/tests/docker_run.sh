#!/bin/bash -eu
set -o pipefail

DOCKER="${DOCKER:-docker}"
IMAGE_NAME=wikimedia
UTILS_DIR=$(readlink -f ../../../../utils)
CONTAINER_NAME=wikimedia_varnish_test_env
PCC_PATH=/utils/pcc
# Fail early if these aren't set rather than waiting until after Docker builds
JENKINS_USERNAME="${JENKINS_USERNAME:?'Jenkins username is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
JENKINS_API_TOKEN="${JENKINS_API_TOKEN:?'Jenkins API token is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
HOST="${1:?\"Usage: $0 <hostname> <change_num_or_pcc_url> [vtc_file_glob='*']\"}"
CHANGE_ID="${2:?\"Usage: $0 <hostname> <change_num_or_pcc_url> [vtc_file_glob='*']\"}"
VTC_FILEGLOB="${3:-}"


$DOCKER build -q -t ${IMAGE_NAME} .
$DOCKER run -it --rm --name ${CONTAINER_NAME} \
    --env JENKINS_USERNAME="${JENKINS_USERNAME}" \
    --env JENKINS_API_TOKEN="${JENKINS_API_TOKEN}" \
    --env VARNISHTEST_CONTAINER=1 \
    --mount type=bind,source="${UTILS_DIR}",target=/utils \
    --mount type=bind,source="$(pwd)",target=/"${IMAGE_NAME}"/varnish \
    ${IMAGE_NAME} varnish/run.py "$HOST" "$CHANGE_ID" "${PCC_PATH}" "${VTC_FILEGLOB}"
