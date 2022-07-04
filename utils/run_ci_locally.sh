#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail
# Script to run CI checks on your local puppet code.
# It uses the same docker image we use to run such tests in
# CI.
usage() {
    cat <<USG
$0 - run tests on your puppet working directory.

USAGE:
[INTERACTIVE=yes] [IMG_VERSION=X.Y.Z] $0 [-h|RAKE_ARGS]

    -h Prints this help message
    RAKE_ARGS are (optional) arguments that get passed directly to "rake" in the container.

You can override the image version to use with the environment variable
IMG_VERSION.

yuo can have the image spin up and drop yu to a bash terminal by setting
INTERACTIVE=yes.


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

# Verify that docker or podman is installed, prefer podman
if command -v podman >/dev/null; then
    oci_runtime='podman'
elif command -v docker >/dev/null; then
    oci_runtime='docker'
    # If using docker verify that the current user has permissions to operate
    # on it.
    if ! docker info >/dev/null; then
        echo "Your current user ($USER) is not authorized to operate on the docker daemon. Please fix that."
        exit 1
    fi
else
    echo "Neither 'docker' nor 'podman' were found in your PATH: '$PATH'. Please install one of them"
    exit 1
fi

INTERACTIVE=${INTERACTIVE:-"no"}
IMG_VERSION=${IMG_VERSION:-"latest"}
IMG_NAME=docker-registry.wikimedia.org/releng/operations-puppet:$IMG_VERSION
CONT_NAME=puppet-tests-${IMG_VERSION}

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
if [ "$IMG_VERSION" = "latest" ]
then
  echo "Using 'latest' image tag, set IMG_VERSION to use a specific version"
  $oci_runtime pull "$IMG_NAME"
fi

pushd "${SCRIPT_DIR}/.."
oci_run_args=(
  '--rm'
  '--env'
  ZUUL_REF=""
  '--env'
  RAKE_TARGET="$*"
  '--name'
  "$CONT_NAME"
  '--volume'
  "$PWD":/src
)
if [ "${INTERACTIVE}" == "yes" ]
then
  echo "starting $oci_runtime in interactive mode."
  echo "you will most likely want to run the following steps"
  echo "bundle update"
  echo "run your custom rspec debug steps e.g."
  echo "cd modules/wmflib && bundle exec rake spec"
  $oci_runtime run "${oci_run_args[@]}" -it --workdir /src --entrypoint bash "$IMG_NAME"
else
  $oci_runtime run "${oci_run_args[@]}" "$IMG_NAME"
fi
popd
