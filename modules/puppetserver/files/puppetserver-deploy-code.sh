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

set -o errexit
set -o nounset

function cleanup {
	local exit_code=$?
	if [[ -v 'old_dir' ]] && [[ -d "$old_dir" ]]; then
		rm -r "$old_dir"
	fi
	return $exit_code
}

trap cleanup SIGINT SIGHUP SIGABRT EXIT

function main {
	local codedir
	codedir=$(puppet config --section server print codedir)
	# g10k populates ${code_dir}/environments_staging
	g10k -quiet -config /etc/puppet/g10k.conf
	new_dir=$(mktemp --directory --tmpdir="${codedir}" env.XXXXXXXXXX)
	mv --no-target-directory \
		"${codedir}/environments_staging" "$new_dir"
	if [[ -L "${codedir}/environments" ]]; then
		old_dir=$(realpath "${codedir}/environments")
	fi
	ln --no-target-directory --symbolic --force \
		"$new_dir" "${codedir}/environments"
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
