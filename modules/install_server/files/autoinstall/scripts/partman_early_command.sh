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
    # We are checking for two SSDs that are less than 3TB in size.
    # These device names will be configured for the RAID array and grub boot devices.
    if grep -q 0 "${disk}"
    then
      device="$(printf "%s" "${disk}" | cut -d/ -f4 -)"
      if [ $(/sbin/blockdev --getsize64 /dev/"${device}") -lt 3000000000000 ]
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
d-i partman-auto-raid/recipe string  \
        1    2    0    ext4    /boot \
            ${boot_parts}      \
        .                            \
        1    2    0    swap    -     \
            ${swap_parts}      \
        .                            \
        1    2    0    lvm    -      \
            ${root_parts}      \
        .
EOF
debconf-set-selections /tmp/dynamic_disc.cfg
}

# The following function is used to remove software RAID metadata from devices required
# for the OS install. This is intended to be used for reimaging cephosd servers, where we
# wish to reinstall the O/S using LVM on MD RAID but leave the LV associated with each OSD
# intact. See #T372783 for more info.
remove_os_md() {
  # Assemble any software RAID arrays that are discovered
  mdadm --assemble --scan || true
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


case $(hostname) in
  ms-be2050|ms-be20[7-9]*|ms-be107[2-9]|ms-be10[8-9]*|moss-*|thanos-be1005|thanos-be2005)
    configure_swift_disks
    ;;
  cephosd*|cloudcephosd*)
    remove_os_md
    configure_cephosd_disks
    ;;
esac

