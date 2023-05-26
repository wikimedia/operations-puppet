#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Set the environment to dev and emit node definitions for the puppet-client
# base image and the dev puppet-server

set -o errexit
set -o nounset

printf 'environment: "dev"\n'
host=$1
case "$host" in
puppet-client.*)
	classes=('role::insetup::container')
	role='insetup/container'
	;;
puppet-server.*)
	classes=('role::puppetserver::dev')
	role='puppetserver/dev'
	;;
esac
if [[ -v classes ]]; then
	printf 'classes:\n'
	for class in "${classes[@]}"; do
		printf '  - "%s"\n' "$class"
	done
fi
if [[ -v role ]]; then
	printf 'parameters:\n'
	printf '  _role: "%s"\n' "$role"
fi
