#!/bin/bash
set -eo pipefail
# Script to run CI checks on your local puppet code.
# It uses the same docker image we use to run such tests in
# CI.
usage() {
    cat <<USG
$0 - run tests on your puppet working directory.

USAGE:
[IMG_VERSION=X.Y.Z] $0 [-h|RAKE_ARGS]

    -h Prints this help message
    RAKE_ARGS are (optional) arguments that get passed directly to "rake" in the container.

You can override the image version to use with the environment variable
IMG_VERSION.

EXAMPLES:
# Run all tests CI would run
$ run_ci_locally.sh

# Print all the available rake tasks for your current change
$ run_ci_locally.sh --tasks

# Execute all spec tests
$ run_ci_locally.sh global:spec
USG
    exit 2
}
if [[ -n "$1" && "$1" == "-h" ]]; then
    usage
fi

# Verify that docker is installed, and that the current user has
# permissions to operate on it.
if ! command -v docker > /dev/null; then
    echo "'docker' was not found in your $PATH. Please install docker"
    exit 1
fi
if ! (docker info > /dev/null); then
    echo "Your current user ($USER) is not authorized to operate on the docker daemon. Please fix that."
    exit 1
fi

IMG_VERSION=${IMG_VERSION:-"0.5.5"}
IMG_NAME=docker-registry.wikimedia.org/releng/operations-puppet:$IMG_VERSION
CONT_NAME=puppet-tests-${IMG_VERSION}

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

pushd "${SCRIPT_DIR}/.."
docker run --rm --env ZUUL_REF="" --env RAKE_TARGET="$@" --name $CONT_NAME --volume /$(pwd)://src $IMG_NAME
popd
