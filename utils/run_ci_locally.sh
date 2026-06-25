#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Script to run CI checks on your local puppet code. It uses the same container
# image we use to run such tests in CI.

set -o errexit
set -o pipefail
set -o nounset
shopt -s lastpipe

usage() {
	cat <<-USG
		$0 - run tests on your puppet working directory.

		USAGE:
		[INTERACTIVE=yes] [IMG_VERSION=X.Y.Z] $0 [-h|RAKE_ARGS]

			-h Prints this help message
			RAKE_ARGS are (optional) arguments that get passed directly to
				"rake" in the container.

		You can override the image version to use with the environment variable
		IMG_VERSION.

		You can have the image spin up and drop you into a bash terminal by
		setting INTERACTIVE=yes.

		EXAMPLES:
		# Run all tests CI would run
		$ run_ci_locally.sh

		# Print all the available rake tasks for your current change
		$ run_ci_locally.sh --tasks

		# Execute all spec tests
		$ run_ci_locally.sh global:spec

		# Run interactively
		$ INTERACTIVE=yes run_ci_locally.sh
		$ bundle exec rspec modules/nftables
	USG
}

if [[ -v 1 && "$1" == "-h" ]]; then
	usage
	exit 0
fi

git_root=$(git rev-parse --show-toplevel)

# Determine container runtime, prefer env var, podman, then docker
if [[ -v 'OCI_RUNTIME' ]] && command -v "$OCI_RUNTIME" >/dev/null; then
	oci_runtime="$OCI_RUNTIME"
elif command -v podman >/dev/null; then
	oci_runtime='podman'
elif command -v docker >/dev/null; then
	oci_runtime='docker'
	# If using docker verify that the current user has permissions to operate
	# on it.
	if ! docker info >/dev/null; then
		echo "Your current user ($USER) is not authorized to operate on the docker daemon. Please fix that." 1>&2
		exit 1
	fi
else
	echo "Neither 'docker' nor 'podman' were found in your PATH: '$PATH'. Please install one of them" 1>&2
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

if ! cont_puppet_dir=$(
	$oci_runtime run \
		--rm \
		--entrypoint '/usr/bin/printenv' \
		"$IMG_NAME" \
		'PUPPET_DIR'
); then
	printf 'Error: unable to determine puppet-dir\n' 1>&2
	exit 1
fi

if ! cont_docker_head=$(
	$oci_runtime run \
		--rm \
		--workdir "$cont_puppet_dir" \
		--entrypoint '/usr/bin/git' \
		"$IMG_NAME" \
		show-ref -s docker-head
); then
	printf 'Error: unable to determine docker-head\n' 1>&2
	exit 1
fi

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
		"$file" = ".mypy_cache" ||
		"$file" = ".bundle" ||
		"$file" = "Gemfile.lock" ]]; then
		continue
	fi
	oci_run_args+=(
		'--volume'
		"$git_root"/"$file":"$cont_puppet_dir"/"$file":ro
	)
done

# Fix platform warning when running on arm64 hosts
# macos reports arm64, Linux reports aarch64
if [[ "$(uname -m)" == "arm64" || "$(uname -m)" == "aarch64" ]] && [ "${oci_runtime}" == "docker" ]; then
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
	pushd "${private_modules_path}" >/dev/null
	git fetch
	if ! commit_count=$(git rev-list --count '@..@{u}'); then
		printf 'Error: unable to determine commit count\n' 1>&2
		exit 1
	fi
	if [[ $commit_count -gt 0 ]]; then
		printf 'Updating private repo fixture\n'
		git pull --ff-only
	fi
	popd >/dev/null
else
	printf 'Cloning private repo fixture\n'
	git clone "$private_repo" "$private_modules_path"
fi

if [ "${INTERACTIVE}" == "yes" ]; then
	cat <<-EOF

		  Started $oci_runtime in interactive mode.
		  Run your custom rspec tests, e.g.:
		  $ bundle exec rspec modules/nftables

	EOF
	$oci_runtime run "${oci_run_args[@]}" \
		--interactive --tty --workdir "$cont_puppet_dir" \
		--entrypoint bash "$IMG_NAME"
else
	$oci_runtime run "${oci_run_args[@]}" "$IMG_NAME"
fi
popd >/dev/null
