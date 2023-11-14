#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Evicts puppetserver's cached code:
# https://www.puppet.com/docs/puppet/7/configuration#environment-timeout

http_code=$(
	curl \
		--silent \
		--show-error \
		--cert "$(puppet config print hostcert)" \
		--key "$(puppet config print hostprivkey)" \
		--cacert "$(puppet config print cacert)" \
		--write-out '%{http_code}\n' \
		--request DELETE \
		"https://$(hostname -f):8140/puppet-admin-api/v1/environment-cache"
)

if [[ $http_code == '204' ]]; then
	printf 'Puppet code cache evicted\n'
	exit 0
else
	printf 'ERROR: Unable to evict puppet code cache, http code %s\n' "$http_code" 1>&2
	exit 1
fi
