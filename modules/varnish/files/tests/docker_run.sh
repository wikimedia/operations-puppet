#!/bin/sh -eu

IMAGE_NAME=wikimedia
UTILS_DIR=$(readlink -f ../../../../utils)
CONTAINER_NAME=wikimedia_varnish_test_env
TEMP_FILE=$(mktemp -t vtcresults.XXXXXXXXXX)
PCC_PATH=/utils/pcc
# Fail early if these aren't set rather than waiting until after Docker builds
JENKINS_USERNAME="${JENKINS_USERNAME:?'Jenkins username is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
JENKINS_API_TOKEN="${JENKINS_API_TOKEN:?'Jenkins API token is missing; See https://wikitech.wikimedia.org/wiki/Help:Puppet-compiler#Catalog_compiler_local_run_(pcc_utility) for more details'}"
HOST="${1:?\"Usage: $0 HOST CHANGE_ID\"}"
CHANGE_ID="${2:?\"Usage: $0 HOST CHANGE_ID\"}"

copy_temp() {
    C_TEMP_FILE=$(grep  -o '/tmp/\w*' "${TEMP_FILE}")
    echo "Copying ${C_TEMP_FILE} from container ${CONTAINER_NAME}"
    docker cp "${CONTAINER_NAME}":"${C_TEMP_FILE}" "${TEMP_FILE}"
    echo "Results copied to ${TEMP_FILE} for your reference."
}

clean_up() {
    echo "Cleaning up ..."
    docker rm -f ${CONTAINER_NAME} > /dev/null
}

docker build -t ${IMAGE_NAME} .
docker run -it --name ${CONTAINER_NAME} \
    --env JENKINS_USERNAME="${JENKINS_USERNAME}" \
    --env JENKINS_API_TOKEN="${JENKINS_API_TOKEN}" \
    --mount type=bind,source="${UTILS_DIR}",target=/utils \
    --mount type=bind,source="$(pwd)",target=/"${IMAGE_NAME}"/varnish \
    ${IMAGE_NAME} varnish/run.py "$HOST" "$CHANGE_ID" "${PCC_PATH}"| tee  "${TEMP_FILE}"

copy_temp
clean_up
