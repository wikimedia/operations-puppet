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
  root_parts=$(printf "%s1#%s1" "${devices% *}" "${devices#* }")
  swap_parts=$(printf "%s" "${root_parts}" | tr '1' '2')
cat > /tmp/dynamic_disc.cfg <<EOF
d-i grub-installer/bootdev  string  ${devices}
d-i partman-auto/disk   string ${devices}
# Parameters are:
# <raidtype> <devcount> <sparecount> <fstype> <mountpoint> \\
#   <devices> <sparedevices>
d-i partman-auto-raid/recipe    string      \\
        1   2   0   ext4    /   \\
            ${root_parts}     \\
        .                   \\
        1   2   0   swap    -   \\
            ${swap_parts}     \\
        .
EOF
debconf-set-selections /tmp/dynamic_disc.cfg
}
case $(hostname) in
  ms-be2050)
    configure_swift_disks
    ;;
esac
