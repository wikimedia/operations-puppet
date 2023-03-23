#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
USAGE=$(
	cat <<-'EOF'
		In place upgrade of Debian to the next release, essentially a
		dist-upgrade wrapper.

		Usage: dist-upgrade
		  -d enable debugging
		  -h this message
		  -r reboot after successful upgrade (default false)
		  -y assume yes to prompts (default false)
	EOF
)

declare -rA CODENAMES=(
	[10]='buster'
	[11]='bullseye'
	[12]='bookworm'
	[13]='trixie'
	[14]='forky'
)

PUPPET_MSG='Upgrading to the next Debian release'

APT_GET_OPTS=(
	'--option'
	'Dpkg::Options::=--force-confdef'
	'--option'
	'Dpkg::Options::=--force-confold'
	'--assume-yes'
)

CMDS=(
	'apt-get'
	'disable-puppet'
	'enable-puppet'
	'grep'
	'puppet'
	'sed'
)

export APT_LISTCHANGES_FRONTEND='none'
export DEBIAN_FRONTEND='noninteractive'

set -o errexit
set -o nounset
set -o pipefail

shopt -s lastpipe
shopt -s inherit_errexit
shopt -s globstar
shopt -s nullglob

function usage {
	printf '%s\n' "$USAGE"
}

cleanup() {
	local exit_code=$?
	if ! puppet-enabled; then
		enable-puppet "$PUPPET_MSG"
	fi
	return $exit_code
}

trap cleanup SIGINT SIGHUP SIGABRT EXIT

# Prompt user for agreement of message provided as $1. Print true if the user
# agrees, false otherwise
function user_agrees {
	local msg
	local resp
	msg=$1
	while true; do
		read -rp "${msg} [y/n]: " resp >/dev/tty
		case $resp in
		[Yy]*)
			printf 'true\n'
			return 0
			;;
		[Nn]*)
			printf 'false\n'
			return 0
			;;
		*)
			printf 'Invalid choice, try again\n' >/dev/tty
			;;
		esac
	done
}

# Increment the debian version by changing /etc/apt/**/*.list to the
# new Debian codename
function bump_debian_version {
	local old_codename=$1
	local new_codename=$2
	pushd /etc/apt >/dev/null
	lists=(**/*.list)
	for list in "${lists[@]}"; do
		# The first substitution updates the old security repo naming in buster
		sed --in-place \
			-e "s#${old_codename}/updates#${new_codename}-security#" \
			-e "s/${old_codename}/${new_codename}/" \
			"$list"
	done
	popd >/dev/null
	apt_update
}

# Prepare for and then run dist-upgrade
function dist_upgrade {
	# Remove packages from disk and cache to free up disk space
	apt-get "${APT_GET_OPTS[@]}" autoremove
	apt-get clean

	read -r var_free_megabytes < <(df --block-size=M --output=avail /var | sed '1d;s/M$//')
	if ((var_free_megabytes < 500)); then
		printf 'There must be at least 500MB of free disk space in /var\n' >&2
		return 1
	fi

	apt-get "${APT_GET_OPTS[@]}" upgrade
	apt-get clean
	apt-get "${APT_GET_OPTS[@]}" dist-upgrade
	apt-get clean
	apt-get "${APT_GET_OPTS[@]}" autoremove
}

# Checks whether the box is ready to be upgrade to a new Debian version. The
# assumption is made that if the current Debian version is fully upgraded then
# we are ready to upgrade to the next version. Debian upgrades are the most
# tested using the latest version of package from the previous release.
#
# Prints true if the box is up to date, false otherwise.
function ready_for_new_debian_version {
	local pkgs_to_upgrade
	local pkgs_to_dist_upgrade
	local pkg_opts_re='^(Inst|Conf) '
	local num_re='^[0-9]+$'
	pkgs_to_upgrade=$(
		apt-get upgrade --simulate |
			grep --count --extended-regexp "${pkg_opts_re}" ||
			[[ $? == 1 ]] # Grep returns 1 when no lines match
	)
	if ! [[ $pkgs_to_upgrade =~ $num_re ]]; then
		return 1
	fi
	pkgs_to_dist_upgrade=$(
		apt-get dist-upgrade --simulate |
			grep --count --extended-regexp "${pkg_opts_re}" ||
			[[ $? == 1 ]] # Grep returns 1 when no lines match
	)
	if ! [[ $pkgs_to_dist_upgrade =~ $num_re ]]; then
		return 1
	fi
	if ((pkgs_to_upgrade == 0 && pkgs_to_dist_upgrade == 0)); then
		printf 'true\n'
	else
		printf 'false\n'
	fi
}

# Prints true if a newer version of a package is available, false otherwise
function pkg_needs_upgrade {
	local pkg
	pkg="${1}"
	declare -A pkg_state
	while IFS=': ' read -r state version; do
		pkg_state+=(["${state}"]="${version}")
	done < <(apt-cache policy "${pkg}" | grep --extended-regexp '(Installed|Candidate)')
	if [[ "${pkg_state['Candidate']}" != "${pkg_state['Installed']}" ]]; then
		printf 'true\n'
	else
		printf 'false\n'
	fi
}

# Updates the package list
function apt_update {
	apt-get update
	# grab the latest keyring to ensure we trust new packages
	upgrade_keyring=$(pkg_needs_upgrade debian-archive-keyring)
	if [[ $upgrade_keyring == 'true' ]]; then
		apt-get "${APT_GET_OPTS[@]}" install debian-archive-keyring
	fi
}

function upgrade_debian {
	local old_version_id=$1
	local new_version_id=$2
	local old_codename=${CODENAMES[$old_version_id]}
	local new_codename=${CODENAMES[$new_version_id]}

	bump_debian_version "$old_codename" "$new_codename"

	dist_upgrade
	# Delete cached facts from prior Debian version
	for cached_fact in /opt/puppetlabs/facter/cache/cached_facts/*; do
		rm "$cached_fact"
	done
	# Re-enable puppet and run it once, we need to do this dance many times,
	# because Puppet doesn't allow you to override its lock,
	# https://tickets.puppetlabs.com/browse/PUP-3761
	enable-puppet "$PUPPET_MSG"
	puppet agent -t
	disable-puppet "$PUPPET_MSG"
	# Run dist-upgrade one more time (since the puppet run might have added
	# some components)
	dist_upgrade
	# Run puppet a second time
	enable-puppet "$PUPPET_MSG"
	puppet agent -t
	disable-puppet "$PUPPET_MSG"

	# Source /etc/os-release again to get our new version number
	source /etc/os-release

	if [[ $VERSION_ID == "$new_version_id" ]]; then
		printf '\nUpgrade from %s(%s) to %s(%s) will complete after a reboot.\n' \
			"${old_codename}" "${old_version_id}" "${new_codename}" "${new_version_id}"
		return 0
	else
		printf '\nUpgrade from %s(%s) to %s(%s) failed!\n' \
			"${old_codename}" "${old_version_id}" "${new_codename}" "${new_version_id}" >&2
		return 1
	fi
}

function main {
	local reboot_lock='/tmp/dist-upgrade-reboot-required.lock'

	if [[ $EUID -ne 0 ]]; then
		printf 'This script must be run as root\n' >&2
		return 1
	fi

	for cmd in "${CMDS[@]}"; do
		if ! command -v "$cmd" >/dev/null; then
			printf 'Required command, (%s) not found in PATH=%s\n' "$cmd" "$PATH" >&2
			return 1
		fi
	done

	local reboot='false'
	local assume_yes='false'
	while getopts ":dhry" opt; do
		case "${opt}" in
		d)
			set -o xtrace
			;;
		r)
			reboot='true'
			;;
		y)
			assume_yes='true'
			;;
		h)
			usage
			return 0
			;;
		\?)
			usage 1>&2
			return 1
			;;
		esac
	done
	shift $((OPTIND - 1))

	if [[ -e "${reboot_lock}" ]]; then
		printf '\nReboot lock file found, (%s),\n' "${reboot_lock}"
		printf 'this means you are trying to perform another upgrade before\n'
		printf 'rebooting, please reboot before performing another upgrade.\n\n'
		return 1
	fi

	# Ensure we have an up to date version of /etc/os-release
	upgrade_base_files=$(pkg_needs_upgrade base-files)
	if [[ $upgrade_base_files == 'true' ]]; then
		if ! disable-puppet "$PUPPET_MSG"; then
			return 1
		fi
		apt-get "${APT_GET_OPTS[@]}" install base-files
		enable-puppet "$PUPPET_MSG"
	fi

	# Grab Debian $VERSION_CODENAME and $VERSION_ID
	source /etc/os-release
	new_version_id=$((VERSION_ID + 1))
	if [[ ! (-v "CODENAMES[$VERSION_ID]" && -v "CODENAMES[$new_version_id]") ]]; then
		printf 'Current Debian version (%d) is not supported for upgrading\n' "${VERSION_ID}" >&2
		printf 'Supported versions are:\n' >&2
		printf '  %s\n' "${!CODENAMES[@]:0:$((${#CODENAMES[@]} - 1))}" >&2
		return 1
	fi

	new_codename=${CODENAMES[$new_version_id]}
	old_codename=${VERSION_CODENAME}
	old_version_id=${VERSION_ID}

	if [[ $assume_yes == 'false' ]]; then
		printf -v upgrade_msg 'Upgrade Debian from %s(%s) to %s(%s)?' \
			"${old_codename}" "${old_version_id}" \
			"${new_codename}" "${new_version_id}"
		if [[ $(user_agrees "${upgrade_msg}") == 'false' ]]; then
			return 0
		fi
	fi

	if ! disable-puppet "$PUPPET_MSG"; then
		return 1
	fi

	apt_update
	ready_for_upgrade=$(ready_for_new_debian_version)
	if [[ $ready_for_upgrade == 'true' ]]; then
		upgrade_debian "$old_version_id" "$new_version_id"
	else
		dist_upgrade
		printf '\nUpgraded all packages for Debian %s(%s).\n' \
			"${old_codename}" "${old_version_id}"
		printf 'Ready to upgrade to Debian %s(%s) after rebooting.\n' \
			"${new_codename}" "${new_version_id}"
	fi

	# Create a reboot lock to prevent folks from running the script again,
	# prior to rebooting
	touch "${reboot_lock}"
	if [[ $reboot == 'true' ]]; then
		printf '\nRebooting!\n\n'
		reboot
	else
		printf '\nPlease Reboot!\n\n'
	fi
}

main "$@"
