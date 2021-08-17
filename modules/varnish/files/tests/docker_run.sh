#!/bin/sh

IMAGE_NAME=wikimedia
UTILS_DIR=$(readlink -f ../../../../utils)
CONTAINER_NAME=wikimedia_varnish_test_env
TEMP_FILE=$(mktemp -t vtcresults.XXXXXXXXXX)
PCC_PATH=/utils/pcc

check_docker() {
    # Verify docker is installed and running
    if ! command -v docker > /dev/null
    then
        echo "Docker is missing please install it first!"
        exit 1
    elif ! systemctl is-active docker.service > /dev/null && \
    ! systemctl is-active docker.socket > /dev/null
    then
        # To capture either distro i.e those that have docker enabled
        # or not enabled by default, we check both docker service and socket
        echo "Docker daemon is not running, please start it first!"
        exit 1
    fi

    # Check user authorization
    if ! docker info > /dev/null 2>&1
    then
        echo "Permission Denied: Ensure user '${USER}' is authorized to run docker commands."
        exit 1
    fi
}

build_image() {
    if ! (docker build -t ${IMAGE_NAME} .)
    then
        echo "Error building image... Exiting now"
        exit 1
    fi
}

check_image_exists() {
    if ! (docker image ls ${IMAGE_NAME} | grep -q ${IMAGE_NAME})
    then
        build_image
    fi
}

check_jenkins_env_vars() {

    if [ -z "${JENKINS_USERNAME}" ] || [ -z "${JENKINS_API_TOKEN}" ]
    then
        echo "JENKINS_USERNAME or JENKINS_API_TOKEN not set or exported."
        echo "Please refer to the README for instructions."
        exit 1
    fi
}

usage() {
    # Prints script usage
    echo "Usage:  ${0} HOSTNAME CHANGE_ID"
    exit 1
}

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

main() {
    check_docker
    check_jenkins_env_vars
    check_image_exists

    docker run -it --name ${CONTAINER_NAME} \
    --env JENKINS_USERNAME="${JENKINS_USERNAME}" \
    --env JENKINS_API_TOKEN="${JENKINS_API_TOKEN}" \
    --mount type=bind,source="${UTILS_DIR}",target=/utils \
    --mount type=bind,source="$(pwd)",target=/"${IMAGE_NAME}"/varnish \
    ${IMAGE_NAME} varnish/run.py "${1}" "${2}" "${PCC_PATH}"| tee  "${TEMP_FILE}"

    copy_temp
    clean_up
}

# Check whether we have the right number of arguments supplied
test $# -eq 2 || usage

main "$@"