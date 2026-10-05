#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# Detect OS devices and output d-i debconf settings.
#
# The use case is hosts with small devices (ssd and/or nvme) dedicated to the
# operating system and larger devices (ssd, disks) used to store data.
# The former get standard recipes: (optional) software raid and LVM
# vg0 on top for root/swap/srv.
#
# When connected to the same hardware raid controller OS device names
# can shift, therefore we can't hardcode them in recipes and have to
# rely on autodetection instead.
#
# In this context "OS device" is defined as any /dev/sd* or /dev/nvme*n*
# block device whose size is at most 'detect_os_device/max_gb' (decimal
# GB and default 1100, just above 1TB and 1TiB).
#
# When more than one OS device is found then software raid is assumed
# and partman instructions are issued accordingly. The raid level
# defaults to 1 unless changed with 'detect_os_device/raid_level'.

set -e
exec 2> /tmp/detect-os-device.log
set -x

# Print /dev paths of sd and nvme devices no bigger than OS_DEVICE_MAX_BYTES
find_os_devices() {
  found_any_device=0

  for sys_path in /sys/block/sd* /sys/block/nvme*; do
    [ -e "$sys_path" ] || continue
    [ -f "$sys_path/size" ] || continue

    found_any_device=1
    dev="${sys_path##*/}"
    sectors=$(cat "$sys_path/size")
    size_bytes=$(( sectors * 512 ))   # /sys/block/*/size is in 512-byte units

    if [ "$size_bytes" -le "$OS_DEVICE_MAX_BYTES" ]; then
      echo "/dev/$dev"
    fi
  done

  if [ "$found_any_device" -eq 0 ]; then
    echo "No sd* or nvme* block devices found." >&2
    return 1
  fi
}

# Build partition path: nvme0n1 -> nvme0n1p3, sda -> sda3
# (any device name ending in a digit needs the 'p' separator)
partition_path() {
  case "$1" in
    *[0-9]) echo "${1}p${2}" ;;
    *)      echo "${1}${2}" ;;
  esac
}

# Usage: get_debconf_number <question> <default>
get_debconf_number() {
  value=$(debconf-get "$1" 2>/dev/null || true)
  case "$value" in
    ''|*[!0-9]*)
      echo "Invalid or missing $1, using default $2" >&2
      echo "$2"
      ;;
    *)
      echo "$value"
      ;;
  esac
}

os_device_max_gb=$(get_debconf_number detect_os_device/max_gb 1100)
# Default to mdraid partition being 3 (efi case for standard recipes).
raid_partno=$(get_debconf_number detect_os_device/raid_partno 3)
raid_level=$(get_debconf_number detect_os_device/raid_level 1)

OS_DEVICE_MAX_BYTES=$(( os_device_max_gb * 1000000000 ))
echo "Using OS device max size: ${os_device_max_gb} GB" >&2

os_devices=$(find_os_devices)

if [ -z "$os_devices" ]; then
  echo "Error: unable to detect OS devices" >&2
  exit 1
fi

echo "$os_devices" | {
  while read -r dev_path; do
    [ -z "$dev_path" ] && continue

    # Accumulate space-separated devices string
    devices="${devices:+$devices }$dev_path"

    # Accumulate #-separated root partitions string
    part=$(partition_path "$dev_path" "$raid_partno")
    root_parts="${root_parts:+$root_parts#}$part"

    dev_count=$(( dev_count + 1 ))
  done

cat <<EOF
d-i partman-auto/disk string ${devices}
d-i grub-installer/bootdev string ${devices}
EOF

  # More than one OS device: request mdraid with lvm on top
  if [ $dev_count -gt 1 ]; then
    cat <<EOF
d-i partman-auto-raid/recipe string \\
    ${raid_level}  ${dev_count}  0  lvm  -  \\
    ${root_parts}  \\
    .
EOF
  fi
}
