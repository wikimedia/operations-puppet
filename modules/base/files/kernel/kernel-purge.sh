#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
USAGE=$(
	cat <<-'EOF'
		Purge kernels that are:
		  not in use,
		  not the Debian default kernel,
		  not manually installed.

		Usage: kernel-purge
		  -h this message (default when no args)
		  -l list kernels to purge (i.e. dry run mode)
		  -p purge kernels (actually remove kernels)
	EOF
)

set -o errexit
set -o nounset
set -o pipefail
shopt -s lastpipe

function usage {
	printf "%s\n" "$USAGE"
}

function main {
	local list='false'
	local purge='false'
	local kernel

	while getopts ":lph" opt; do
		case "${opt}" in
		l)
			list='true'
			;;
		p)
			purge='true'
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
	shift "$((OPTIND - 1))"

	if [[ $list == 'false' && $purge == 'false' ]]; then
		usage
		return 1
	fi

	if [[ $list == 'true' && $purge == 'true' ]]; then
		printf 'You must choose either purge or list, not both\n' 1>&2
		return 1
	fi

	if [[ $purge == 'true' && $UID -ne 0 ]]; then
		printf 'You must be root to purge kernels!\n' 1>&2
		return 1
	fi

	source /etc/os-release
	# We assume the box is Debian Testing or Sid, and newer than Bullseye, if
	# VERSION_ID is not set.
	if [[ -v VERSION_ID && $VERSION_ID -lt 11 ]]; then
		printf 'Only Debian Bullseye or newer has the autoremove logic\n' 1>&2
		return 1
	fi

	declare -A kernels_to_keep=()
	# Keep manually installed kernels
	apt-mark showmanual 'linux-image-[1-9]*' |
		while read -r kernel; do
			kernels_to_keep[$kernel]='Manually installed'
		done

	# Keep the kernel we are running now
	local running_kernel
	local dpkg_status
	running_kernel="linux-image-$(uname -r)"
	dpkg_status=$(dpkg-query --showformat='${Status}' --show "$running_kernel")
	if [[ $dpkg_status == 'install ok installed' ]]; then
		kernels_to_keep[$running_kernel]='Running kernel'
	else
		printf 'Unable to find the deb for the running kernel: %s\n' "$running_kernel" 1>&2
		return 1
	fi

	# Keep Debian's default kernel for this arch, if the meta package is
	# installed
	local def_kernel
	local arch
	arch=$(dpkg --print-architecture)
	if def_kernel=$(dpkg-query --showformat='${Depends}\n' --show 'linux-image-'"$arch"); then
		read -r default_kernel_dep _ <<<"$def_kernel"
		kernels_to_keep[$default_kernel_dep]='Default kernel'
	fi

	declare -a auto_removed_kernels=()
	apt-get autoremove --dry-run |
		while read -r action deb _; do
			if [[ $action == 'Remv' && $deb =~ ^linux-image-[1-9]* ]]; then
				auto_removed_kernels+=("$deb")
			fi
		done

	declare -A kernels_to_purge=()
	for kernel in "${auto_removed_kernels[@]}"; do
		if [[ ! -v "kernels_to_keep[$kernel]" ]]; then
			kernels_to_purge[$kernel]='Autoremove'
		fi
	done

	printf "Kernels to keep:\n"
	for kernel in "${!kernels_to_keep[@]}"; do
		printf '  %s\t%s\n' "$kernel" "${kernels_to_keep[$kernel]}"
	done

	if [[ "${#kernels_to_purge[@]}" -eq 0 ]]; then
		printf "No kernels to purge\n"
		return 0
	fi

	if [[ $list == 'true' ]]; then
		printf "Kernels to purge:\n"
		for kernel in "${!kernels_to_purge[@]}"; do
			printf '  %s\t%s\n' "$kernel" "${kernels_to_purge[$kernel]}"
		done
	fi

	declare -a purged=()
	if [[ $purge == 'true' ]]; then
		for kernel in "${!kernels_to_purge[@]}"; do
			apt-get purge -y "${kernel}"
			purged+=("${kernel}")
		done
		printf "Purged kernels:\n"
		for kernel in "${purged[@]}"; do
			printf '  %s\n' "$kernel"
		done
	fi
}

main "$@"
