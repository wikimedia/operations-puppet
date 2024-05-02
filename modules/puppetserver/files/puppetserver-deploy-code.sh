#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# The script tries to update puppetserver's code in an atomic-ish way,
# puppetserver is not known to support a completely atomic online option.
#
# 1. Pull code via g10k
# 2. Move code to a unique dir
# 3. Swap code via a symlink
# 4. Evict puppetserver's cached code:
#	 - https://www.puppet.com/docs/puppet/7/configuration#environment-timeout
#
# TODO:
# - support deploying other environments, we can't symlink
#   ${codedir}/environments, because puppetserver manages that directory and will
#   overwrite the symlink with a directory

set -o errexit
set -o nounset

function cleanup {
	local exit_code=$?
	if [[ -v 'OLD_DIR' ]] && [[ -d "$OLD_DIR" ]]; then
		rm -r "$OLD_DIR"
	fi
	return $exit_code
}

trap cleanup SIGINT SIGHUP SIGABRT EXIT

function main {
	local codedir envdir g10k_envdir new_dir
	codedir=$(puppet config --section server print codedir)
	if ! current_branch=$(git -C /srv/git/operations/puppet/ branch --show-current); then
		printf 'ERROR: Unable to obtain the current branch\n' 1>&2
		exit 1
	fi
	if [[ "$current_branch" != 'production' ]]; then
		printf 'ERROR: Current branch in /srv/git/operations/puppet is "%s", should be "production"\n' "$current_branch" 1>&2
		printf 'ERROR: Exiting rather than deploying something surprising\n' 1>&2
		exit 1
	fi
	envdir="${codedir}/environments"
	g10k_envdir="${codedir}/environments_staging"
	# g10k populates ${codedir}/environments_staging/production
	g10k -quiet -branch production -config /etc/puppet/g10k.conf
	new_dir=$(mktemp --directory --tmpdir="${envdir}" env.XXXXXXXXXX)
	mv --no-target-directory \
		"${g10k_envdir}/production" "$new_dir"
	if [[ -L "${envdir}/production" ]]; then
		OLD_DIR=$(realpath "${envdir}/production")
	fi
	ln --no-target-directory --symbolic --force \
		"$new_dir" "${envdir}/production"
	printf 'INFO: Puppet code deployed\n'

	if http_code=$(
		curl \
			--silent \
			--show-error \
			--cert "$(puppet config --section server print hostcert)" \
			--key "$(puppet config --section server print hostprivkey)" \
			--cacert "$(puppet config --section server print cacert)" \
			--write-out '%{http_code}\n' \
			--request DELETE \
			"https://$(hostname -f):8140/puppet-admin-api/v1/environment-cache"
	); then
		if [[ $http_code == '204' ]]; then
			printf 'INFO: Puppet code cache evicted\n'
			return 0
		else
			printf 'ERROR: Unable to evict puppet code cache, http code %s\n' "$http_code" 1>&2
			return 1
		fi
	else
		printf 'ERROR: Unable to evict puppet code cache\n' 1>&2
		return 1
	fi
}

main "$@"
