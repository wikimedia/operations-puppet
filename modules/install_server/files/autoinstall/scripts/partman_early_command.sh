#! /bin/sh

set -e
configure_swift_disks() {
  devices=""
  for disk in /sys/block/*/queue/rotational
  do
    if grep -q 0 "${disk}"
    then
      device="$(printf "%s" "${disk}" | cut -d/ -f4 -)"
      expr "${device}" : "sd.$" && devices="${devices## } /dev/${device}"
    fi
  done
  root_parts=$(printf "%s2#%s2" "${devices% *}" "${devices#* }")
cat > /tmp/dynamic_disc.cfg <<EOF
d-i partman-auto/disk   string ${devices}
d-i grub-installer/bootdev  string  ${devices}
# Parameters are:
# <raidtype> <devcount> <sparecount> <fstype> <mountpoint> \\
#   <devices> <sparedevices>
d-i partman-auto-raid/recipe    string      \\
        1   2   0   ext4    /   \\
            ${root_parts}     \\
        .
EOF
debconf-set-selections /tmp/dynamic_disc.cfg
}

configure_cephosd_disks() {
  devices=""
  for disk in /sys/block/sd*/queue/rotational
  do
    # We are checking for two SSDs that are less than 1.5TB in size.
    # These device names will be configured for the RAID array and grub boot devices.
    if grep -q 0 "${disk}"
    then
      device="$(printf "%s" "${disk}" | cut -d/ -f4 -)"
      if [ $(/sbin/blockdev --getsize64 /dev/"${device}") -lt 1500000000000 ]
        then
          devices="${devices## } /dev/${device}"
        fi
    fi
  done
  # Double checking that we have exactly two SCSI devices
  num_devices=$(echo ${devices} | egrep -o '\/dev\/sd[a-z]'|wc -l)
  if [ ${num_devices} -ne 2 ]
  then
    echo "We expected to find two boot devices, but instead found ${num_devices}".
    exit 1
  fi
  boot_parts=$(printf "%s1#%s1" "${devices% *}" "${devices#* }")
  swap_parts=$(printf "%s2#%s2" "${devices% *}" "${devices#* }")
  root_parts=$(printf "%s3#%s3" "${devices% *}" "${devices#* }")

cat > /tmp/dynamic_disc.cfg <<EOF
d-i partman-auto/disk   string ${devices}
d-i grub-installer/bootdev  string  ${devices}
# Parameters are:
# <raidtype> <devcount> <sparecount> <fstype> <mountpoint> \\
#   <devices> <sparedevices>
d-i partman-auto-raid/recipe string  \\
        1    2    0    ext4    /boot \\
            ${boot_parts}      \\
        .                            \\
        1    2    0    swap    -     \\
            ${swap_parts}      \\
        .                            \\
        1    2    0    lvm    -      \\
            ${root_parts}      \\
        .
EOF
debconf-set-selections /tmp/dynamic_disc.cfg
}

# The following function is used to remove software RAID and LVM metadata from devices required
# for the OS install. This is intended to be used for reimaging cephosd servers, where we
# wish to reinstall the O/S using LVM on MD RAID but leave the LV associated with each OSD
# intact. See #T372783 for more info.
remove_os_md() {
  # Assemble any software RAID arrays that are discovered
  mdadm --assemble --scan || true
    # Disable any swap devices that are actively using MD RAID devices
  SWAPDEVS=$(sed -n 's#^\(/dev/md[0-9]*\).*#\1#p' /proc/swaps)
  if [ -n "$SWAPDEVS" ]; then
    for d in ${SWAPDEVS}; do
      swapoff ${d}
    done
  fi
  # Identify any physical volumes that are stored on MD RAID devices
  PV=$(pvs -o pv_name --select 'pv_name=~/dev/md' --noheadings)
  if [ -n "$PV" ]; then
    # Remove all logical volumes, the volume group maching the hostname, and the physical volume.
    lvremove -ff -y --devices ${PV} --select all
    vgremove -ff -y $(hostname)-vg
    pvremove -ff -y ${PV}
  fi
  # Identify all member devices of software RAID arrays, stop the array and zero the MD metadata on each one.
  DEVS=$(grep 'md' /proc/mdstat | tr ' ' '\n' | sed -n 's|^|/dev/|;s/\[.*//p')
  if [ -n "$DEVS" ]; then
    for n in /dev/md/*; do
      mdadm --stop ${n}
    done
    for device in ${DEVS}; do
      mdadm --zero-superblock ${device}
    done
  fi
}

# When creating PVs on mdraid devices LVM will align metadata areas with
# reported optimal_io_size. If the component devices report large values
# then the resulting raid will also report a large(er) optimal_io_size,
# tricking LVM into creating a large metadata area. This in turn
# confuses GRUB when trying to allocate memory based on the area size.
# See also https://phabricator.wikimedia.org/T407586 for details.
mpt3sas_optimal_io_workaround() {
  for i in /sys/block/sd*/queue/optimal_io_size; do
    if [ $(cat $i) -eq 0 ]; then
      continue
    fi

    mkdir -p /etc/lvm
    # Disable data alignment detection during installation. The default
    # 1MB alignment is the same when optimal_io_size is reported as 0.
    echo 'devices { data_alignment_detection = 0 }' > /etc/lvm/lvmlocal.conf
    break
  done
}

if lsmod | grep -q mpt3sas; then
  mpt3sas_optimal_io_workaround
fi

# Though we specify that EFI partitions should be formatted. The Debian
# installer never formats EFI partitions which contain an existing
# filesystem[1]. This causes problems with Linux MD RAID boxes where we mirror
# the EFI partition. The dup-efi script copies the entire partition, so the
# partion UUIDs match. However, if Debian doesn't re-format on re-image, Linux
# may mount the partition that the Debian installer did not update and which
# points to the wrong root disk. If that occurs, dup-efi will then dutifully
# sync the broken partition over the working partition.
#
# - [1]: https://salsa.debian.org/installer-team/partman-efi/-/blob/c60be3d4e52bd504825717e8a0e173098814f095/commit.d/format_efi#L37
for part in $(blkid --match-token TYPE=vfat --output device); do
  eval "$(blkid --probe "$part" --output export)"
  if [ "$PART_ENTRY_TYPE" = 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b' ]; then
    mkfs.fat -F 32 "$part"
  fi
  unset PART_ENTRY_TYPE
done

case $(hostname) in
  apus-fe*|ms-be2050|ms-be206[2-9]|ms-be20[7-9]*|ms-be106[679]|ms-be10[7-9]*|ms-be11*|moss-*|thanos-be100[5-9]|thanos-be200[5-9]|sretest2010)
    configure_swift_disks
    ;;
  cephosd*|cloudcephosd*)
    remove_os_md
    configure_cephosd_disks
    ;;
esac

