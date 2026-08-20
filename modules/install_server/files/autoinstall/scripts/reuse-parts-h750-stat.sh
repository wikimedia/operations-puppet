#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# Generates the partman/reuse_partitions_recipe for the H750-based stat
# hosts, whose layout was created by partman/H750hwraid-2dev.cfg: a hardware
# RAID1 OS volume (/boot partition plus the vg0 PV) and a hardware RAID10
# /srv volume (the vg1 PV), with no swap LV.
#
# The controller does not present the two volumes in a stable order across
# boots, so detect them via their LVM volume groups instead of hardcoding
# device names. grub-installer/bootdev is pointed at the OS volume,
# overriding the /dev/sda default from common.cfg.

set -e

log() {
    logger -t reuse-parts-h750-stat "$@"
    echo "reuse-parts-h750-stat: $*" >&2
}

get_pv() {
    pvs --noheadings -o pv_name,vg_name | awk -v vg="$1" '$2 == vg {print $1}'
}

os_pv=$(get_pv vg0)
srv_pv=$(get_pv vg1)
if [ -z "$os_pv" ] || [ -z "$srv_pv" ]; then
    log "ERROR: expected one PV each for vg0 and vg1, got vg0='$os_pv' vg1='$srv_pv'. pvs reports: $(pvs 2>&1)"
    exit 1
fi

# e.g. /dev/sda2 -> disk /dev/sda, partition number 2
os_pv_partnum=$(echo "$os_pv" | sed 's/^.*[^0-9]//')
srv_pv_partnum=$(echo "$srv_pv" | sed 's/^.*[^0-9]//')
if [ -z "$os_pv_partnum" ] || [ -z "$srv_pv_partnum" ]; then
    log "ERROR: unable to determine partition numbers from PVs $os_pv and $srv_pv"
    exit 1
fi
os_disk=${os_pv%"$os_pv_partnum"}
srv_disk=${srv_pv%"$srv_pv_partnum"}
if [ "$os_disk" = "$srv_disk" ]; then
    log "ERROR: vg0 and vg1 both resolve to $os_disk, expected separate disks"
    exit 1
fi

recipe="$os_disk|1 ext4 format /boot|$os_pv_partnum lvmpv ignore none"
recipe="$recipe, $srv_disk|$srv_pv_partnum lvmpv ignore none"
recipe="$recipe, /dev/mapper/vg0-root|1 ext4 format /"
recipe="$recipe, /dev/mapper/vg1-srv|1 ext4 keep /srv"

log "OS volume: $os_disk (PV $os_pv), srv volume: $srv_disk (PV $srv_pv)"
log "Generated recipe: $recipe"

cat > /tmp/reuse-parts-h750-stat.cfg <<EOF
d-i partman/reuse_partitions_recipe string $recipe
d-i grub-installer/bootdev string $os_disk
EOF
debconf-set-selections /tmp/reuse-parts-h750-stat.cfg
