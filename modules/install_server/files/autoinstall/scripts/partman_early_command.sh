#! /bin/sh

set -e
configure_swift_disks() {
  devices=""
  for disk in /sys/block/*/queue/rotational
  do
    grep -q 0 "${disk}" && devices="${devices} $(echo "${disk}" | awk -F/ '{print $4}')"
  done
  devices_hash_sep=$(echo "${devices}" | tr ' ' '#')
cat > /tmp/dynamic_disc.cfg <<EOF
d-i partman-auto/method     string  raid
d-i partman-md/device_remove_md boolean true
d-i partman-lvm/device_remove_lvm   boolean true
d-i partman-auto/disk   string ${devices}
d-i grub-installer/bootdev  string  ${devices}
# this workarounds LP #1012629 / Debian #666974
# it makes grub-installer to jump to step 2, where it uses bootdev
d-i grub-installer/only_debian  boolean false
# Define physical partitions
d-i partman-auto/expert_recipe  string  \
        multiraid ::    \
            60000   8000    60000   raid        \
                \$primary{ } method{ raid }  \
            .                   \
            1000    1000    1000    raid        \
                \$primary{ } method{ raid }  \
            .                   \
            200000  500 240000  xfs     \
                \$primary{ } method{ format }    \
                format{ } use_filesystem{ } \
                filesystem{ xfs }       \
            . \
            30000   10000   -1  xfs     \
                \$primary{ } method{ format }    \
                format{ } use_filesystem{ } \
                filesystem{ xfs }       \
# Parameters are:
# <raidtype> <devcount> <sparecount> <fstype> <mountpoint> \
#   <devices> <sparedevices>
d-i partman-auto-raid/recipe    string      \
        1   2   0   ext4    /   \
            ${devices_hash_sep}     \
        .                   \
        1   2   0   swap    -   \
            ${devices_hash_sep}     \
        .
EOF
debconf-set-selections /tmp/dynamic_disc.cfg
}
case $(hostname) in
  ms-be2050)
    configure_swift_disks
    ;;
esac
