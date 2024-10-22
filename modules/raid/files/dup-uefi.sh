#!/usr/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Finds the /boot/efi partition and duplicates it onto all other EFI system
# partitions and then adds an EFI boot entry for each partition. This allows MD
# software raid boxes to survive a disk failure, as the EFI system partition is
# not mirrored via raid. Since /boot/efi is mounted via its filesystem UUID and
# the UUIDs are duplicated, the first one found will be mounted by systemd.
#
# There are a variety of other ways to solve this problem:
#
# 1. Use mdadm to create a RAID1 volume of the UEFI parts, using metadata
# version 1.0[2]. This would require a re-image or managing mdadm in Puppet.
# partman does not support metadata version 1.0[5].
#
# 2. Use two non-identical UEFI partitions. This works, but /boot/efi is mounted
# based on the filesystem UUID, so when a disk fails, the system is placed in
# emergency mode. We could set the mount options to `nofail` but the mount
# options are hardcoded in partman and we don't manage `fstab` in Puppet.
#
# This script can be run as a daily systemd timer. Debian's wiki suggests[1]
# placing a similar script in /etc/grub.d, but this seems awkward as the scripts
# in that directory are used to build the grub config, so installing grub while
# building the config seems unnecessarily messy and we don't want to wait for a
# grub update.
#
# Resources:
# - [1]: https://wiki.debian.org/UEFI?highlight=%28efi%29%7C%28raid%29%7C%28grub%29#RAID_for_the_EFI_System_Partition
# - [2]: https://std.rocks/gnulinux_mdadm_uefi.html
# - [3]: https://github.com/ossobv/vcutil/blob/87896cfa635c6248b6f5d2324638e63750e74b2a/efibootmirrorsetup
# - [4]: https://github.com/mschmitt/Dotfiles/blob/11cbfd92e1088f858e37efc0bc28825bb5ed7840/Scripts/sbin/efirepl
# - [5]: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=815569
#
# Testing:
#
# This script was tested on hardware, but it can also be tested with qemu.
# Filippo's gitlab.wikimedia.org:repos/sre/preseed-test.git works great.
#
#     $ cp $partman/standard-efi.cfg preseed.d/
#     $ cp $partman/raid1-2dev-efi.cfg preseed.d/
#     $ ./test.sh prep
#     $ ./test.sh build
#     $ ./test.sh --boot-mode uefi --num-drives 2 install
#     $ ./test.sh --boot-mode uefi --num-drives 2 run
#     # install script
#     # Simulate disk failure, poweroff
#     $ rm workdir/disks/disk1.qcow2
#     # Re-create blank disk
#     $ ./test.sh --num-drives 2 create-disks
#

set -o errexit
set -o nounset

# Cribbed from: https://askubuntu.com/a/162896
if ! [[ -d /sys/firmware/efi ]]; then
	printf 'Booted via BIOS, nothing to do, exiting\n'
	exit 0
fi

if [[ "$EUID" -ne 0 ]]; then
	printf "Error: must be run as root\n" 1>&2
	exit 1
fi

deps=(
	'efibootmgr'
	'lsblk'
	'sha1sum'
	'udevadm'
)
for dep in "${deps[@]}"; do
	if ! command -v "$dep" >/dev/null; then
		printf "Error: dependency %s not available\n" "$dep" 1>&2
		exit 1
	fi
done

declare boot_efi_part
declare -a nonboot_efi_parts=()

# All EFI System partitions should match this partition type
EFI_SYS_PART='c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
while IFS='' read -r lsblk_line; do
	eval "$lsblk_line"
	if [[ $PARTTYPE == "$EFI_SYS_PART" ]]; then

		if [[ $MOUNTPOINT == '/boot/efi' ]]; then
			boot_efi_part="/dev/${NAME}"
		else
			nonboot_efi_parts+=("/dev/${NAME}")
		fi

	fi
done < <(lsblk --shell --pairs --output NAME,MOUNTPOINT,PARTTYPE)

if [[ ! -v "boot_efi_part" ]] || [[ ! -n "$boot_efi_part" ]]; then
	printf "Error: Unable to find /boot/efi device\n" 1>&2
	exit 1
fi

if [[ ${#nonboot_efi_parts[@]} -eq 0 ]]; then
	printf "Info: Found no UEFI parts to duplicate from /boot/efi\n" 1>&2
	exit 0
fi

loader='\EFI\debian\grubx64.efi'
if [[ ! -f "/boot/efi${loader//\\/\/}" ]]; then
	printf "Error: Unable to find loader %s\n" "$loader" 1>&2
	exit 1
fi
printf "Info: Unmounting %s\n" "$boot_efi_part" 1>&2
umount "$boot_efi_part"
remount() {
	local exit_code=$?
	if ! findmnt --source "$boot_efi_part" >/dev/null; then
		printf "Info: Remounting %s\n" "$boot_efi_part" 1>&2
		mount "$boot_efi_part"
	fi
	return $exit_code
}
trap remount SIGINT SIGHUP SIGABRT EXIT
if ! boot_efi_part_sha1sum=$(sha1sum "$boot_efi_part"); then
	printf "Error: Unable to gen sha1sum %s\n" "$boot_efi_part" 1>&2
	exit 1
fi
read -r boot_sum _ <<<"$boot_efi_part_sha1sum"
# Check if all other EFI partitions have the same sha1sum as the partition
# mounted on /boot/efi, if not, copy the /boot/efi partition to the other
# partition.
for nonboot_efi_part in "${nonboot_efi_parts[@]}"; do
	if ! nonboot_efi_part_sha1sum=$(sha1sum "$nonboot_efi_part"); then
		printf "Error: Unable to gen sha1sum %s\n" "$nonboot_efi_part" 1>&2
		exit 1
	fi
	read -r nonboot_sum _ <<<"$nonboot_efi_part_sha1sum"
	if [[ "$boot_sum" == "$nonboot_sum" ]]; then
		printf "Info: Skipping, %s and %s are already identical\n" "$boot_efi_part" "$nonboot_efi_part" 1>&2
	else
		if ! cat "$boot_efi_part" >"$nonboot_efi_part"; then
			printf "Error: Catting %s to %s\n" "$boot_efi_part" "$nonboot_efi_part" 1>&2
			exit 1
		fi
		printf "Info: %s and %s are now identical\n" "$boot_efi_part" "$nonboot_efi_part" 1>&2
	fi
	# lsblk only gained PARTN support in trixie, so use udevadm instead
	if ! udevadm_out=$(udevadm info --query=property --property=PARTN "$nonboot_efi_part"); then
		printf "Error: getting udevadm output for %s\n" "$nonboot_efi_part" 1>&2
		exit 1
	fi
	eval "$udevadm_out"
	if ! lsblk_out=$(lsblk --shell --pairs --output PARTUUID,PKNAME "$nonboot_efi_part"); then
		printf "Error: getting lsblk output for %s\n" "$nonboot_efi_part" 1>&2
		exit 1
	fi
	eval "$lsblk_out"
	# We can drop -v when trixe is the oldest in our fleet
	if ! efibootmgr_out=$(efibootmgr -v); then
		printf "Error: getting efibootmgr output for %s\n" "$nonboot_efi_part" 1>&2
		exit 1
	fi
	# After cloning the partition, we explicitly add a boot entry with
	# efibootmgr, unless one already exists.
	#
	# NOTE:
	#  - We could use grub's --recheck flag, rather than efibootmgr, but grub's
	#    flag also changes the install path, which is annoying.
	#  - efibootmgr complains if labels are identical, which is annoying, so we
	#    will add the PARTUUID to the label, which is also annoying
	#  - efibootmgr changes boot order so that the new option is first, but this
	#    shouldn't matter since the disk is identical
	if ! grep --quiet "$PARTUUID" <<<"$efibootmgr_out"; then
		efibootmgr \
			--quiet \
			--create \
			--disk "/dev/${PKNAME}" \
			--part "$PARTN" \
			--label "debian ${PARTUUID}" \
			--loader "$loader"
		printf 'Info: Added EFI boot option for grub on %s\n' "$nonboot_efi_part" 1>&2
	fi
done
