#!/bin/sh -eu
# SPDX-License-Identifier: Apache-2.0

IMAGE_NAME=wikimedia-haproxy
UTILS_DIR=$(readlink -f ../../../../../../utils/)
CONTAINER_NAME=wikimedia_haproxy_test_env
TEMP_FILE=$(mktemp -t haproxytestresults.XXXXXX)
PCC_PATH=/utils/pcc
# Fail early if these aren't set rather than waiting until after Docker builds
JENKINS_USERNAME="${JENKINS_USERNAME:?'Jenkins username is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
JENKINS_API_TOKEN="${JENKINS_API_TOKEN:?'Jenkins API token is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
HOST="${1:?\"Usage: $0 HOST CHANGE_ID\"}"
CHANGE_ID="${2:?\"Usage: $0 HOST CHANGE_ID\"}"

clean_up() {
    echo "[*] Cleaning up ..."
    docker rm -f ${CONTAINER_NAME} > /dev/null
}

docker build -t ${IMAGE_NAME} .
docker run -it --name ${CONTAINER_NAME} \
    --env JENKINS_USERNAME="${JENKINS_USERNAME}" \
    --env JENKINS_API_TOKEN="${JENKINS_API_TOKEN}" \
    --mount type=bind,source="${UTILS_DIR}",target=/utils \
    --mount type=bind,source="$(pwd)",target=/haproxy \
    ${IMAGE_NAME} /haproxy/run.py "$HOST" "$CHANGE_ID" --pcc "${PCC_PATH}" -l INFO| tee  "${TEMP_FILE}"

echo "[*] A copy of this output can be found in $TEMP_FILE"
clean_up
