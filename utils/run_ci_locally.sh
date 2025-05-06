#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -eo pipefail
shopt -s lastpipe
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

git_root=$(git rev-parse --show-toplevel)

if [ -n "$OCI_RUNTIME" ] && command -v "$OCI_RUNTIME" >/dev/null; then
	oci_runtime="$OCI_RUNTIME"
# Verify that docker or podman is installed, prefer podman
elif command -v podman >/dev/null; then
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

if [ "$IMG_VERSION" = "latest" ]; then
	echo "Using 'latest' image tag, set IMG_VERSION to use a specific version"
	$oci_runtime pull "$IMG_NAME"
fi

cont_puppet_dir=$(
	$oci_runtime run \
		--rm \
		--entrypoint '/usr/bin/printenv' \
		"$IMG_NAME" \
		'PUPPET_DIR'
)
cont_docker_head=$(
	$oci_runtime run \
		--rm \
		--workdir "$cont_puppet_dir" \
		--entrypoint '/usr/bin/git' \
		"$IMG_NAME" \
		show-ref -s docker-head
)

pushd "${git_root}" >/dev/null
oci_run_args=(
	'--rm'
	'--env'
	ZUUL_REF=""
	'--env'
	RAKE_TARGET="$*"
	'--env'
	CONT_DOCKER_HEAD="$cont_docker_head"
	'--name'
	"$CONT_NAME"
)

# Mount each file or directory in the root of our local repo over the same file
# in the container repo root, exclude testing dependencies of ruby & python.
# This totals 42 mounts at the time of this writing, which seems a bit
# ludicrous, but seems to work fine in practice.
find "$git_root" -mindepth 1 -maxdepth 1 -printf '%f\n' |
	mapfile -t git_root_files
for file in "${git_root_files[@]}"; do
	if [[ "$file" = ".tox" ||
		"$file" = ".bundle" ||
		"$file" = "Gemfile.lock" ]]; then
		continue
	fi
	oci_run_args+=(
		'--volume'
		"$git_root"/"$file":"$cont_puppet_dir"/"$file":ro
	)
done

# Fix platform warning when running on M1/M2 macs
if [ "$(uname -m)" == "arm64" ] && [ "${oci_runtime}" == "docker" ]; then
	oci_run_args+=(
		'--platform'
		'linux/amd64'
	)
fi

# Update the private repo, dup of Rakefile logic, to avoid needing rake deps to
# run, we can't do this in the container, because the file system is mounted
# readonly
private_repo='https://gerrit.wikimedia.org/r/labs/private'
fixture_path="${git_root}/spec/fixtures"
private_modules_path="${fixture_path}/private"
if [[ -e "${private_modules_path}/.git" ]]; then
	git -C "$private_modules_path" pull --ff-only
else
	git clone "$private_repo" "$private_modules_path"
fi

if [ "${INTERACTIVE}" == "yes" ]; then
	echo "starting $oci_runtime in interactive mode."
	echo "you will most likely want to run the following steps"
	echo "bundle update"
	echo "run your custom rspec debug steps e.g."
	echo "cd modules/wmflib && bundle exec rake spec"
	$oci_runtime run "${oci_run_args[@]}" -it --workdir /src --entrypoint bash "$IMG_NAME"
else
	$oci_runtime run "${oci_run_args[@]}" "$IMG_NAME"
fi
popd >/dev/null
