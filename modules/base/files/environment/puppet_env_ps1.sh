#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Most shells support local vars
# shellcheck disable=SC3043

if [ "$TERM" != "unknown" ]; then
	GREEN=$(tput setaf 2)
	MAGENTA=$(tput setaf 5)
	RESET_ATTR=$(tput sgr0)
	BOLD=$(tput bold)
else
	GREEN=""
	MAGENTA=""
	RESET_ATTR=""
	BOLD=""
fi

# Prints out a string suitable for a PS1 with the current puppet environment as
# found in /etc/puppet/puppet.conf, production is shown in magenta, other
# environments are in green.
puppet_env_ps1() {
	# preserve exit status
	local exit=$?
	if ! [ -r /etc/puppet/puppet.conf ]; then
		return $exit
	fi
	while IFS='= ' read -r key val; do
		if [ "$key" = 'environment' ]; then
			printf '(env: '
			if [ "$val" = 'production' ]; then
				printf '%s%s' "$MAGENTA" "$BOLD"
			else
				printf '%s' "$GREEN"
			fi
			printf '%s%s)\n' "$val" "$RESET_ATTR"
		fi
	done </etc/puppet/puppet.conf
	return $exit
}
