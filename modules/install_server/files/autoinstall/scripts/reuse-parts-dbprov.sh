#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# Generates the partman/reuse_partitions_recipe for the dbprov hosts, which
# have two hardware RAID volumes:
# - the OS volume: / (ext4), swap and the PV of the tank VG (tank-data on /srv)
# - the dumps volume: a single xfs partition (/srv/backups/dumps/ongoing)
#
# The controller does not present the two volumes in a stable order (it
# changes across installs and boots), so detect them via the tank volume
# group instead of hardcoding device names. grub-installer/bootdev is pointed
# at the OS volume, overriding the /dev/sda default from common.cfg.

set -e

log() {
    logger -t reuse-parts-dbprov "$@"
    echo "reuse-parts-dbprov: $*" >&2
}

fail() {
    log "ERROR: $*"
    exit 1
}

os_pv=$(pvs --noheadings -o pv_name,vg_name | awk '$2 == "tank" {print $1}')
if [ -z "$os_pv" ]; then
    fail "no PV found for VG tank. pvs reports: $(pvs 2>&1)"
fi
if [ "$(echo "$os_pv" | wc -l)" -ne 1 ]; then
    fail "expected a single PV for VG tank, got: $os_pv"
fi

# e.g. /dev/sdb3 -> disk /dev/sdb, partition number 3
os_pv_partnum=$(echo "$os_pv" | sed 's/^.*[^0-9]//')
if [ "$os_pv_partnum" != "3" ]; then
    fail "expected the tank PV to be partition 3 of the OS volume, got $os_pv"
fi
os_disk=${os_pv%"$os_pv_partnum"}

# The dumps volume is the other disk whose first partition is xfs
dumps_disk=""
for sys_path in /sys/block/sd*; do
    [ -e "$sys_path" ] || continue
    disk="/dev/${sys_path##*/}"
    [ "$disk" = "$os_disk" ] && continue
    if [ "$(blkid -o value -s TYPE "${disk}1" 2>/dev/null)" = "xfs" ]; then
        if [ -n "$dumps_disk" ]; then
            fail "found more than one candidate dumps volume: $dumps_disk $disk"
        fi
        dumps_disk=$disk
    fi
done
if [ -z "$dumps_disk" ]; then
    fail "no dumps volume (xfs on partition 1) found besides $os_disk"
fi

recipe="$os_disk|1 ext4 format /|2 linux-swap swap none|3 unknown ignore none"
recipe="$recipe, /dev/mapper/tank-data|1 xfs keep /srv"
recipe="$recipe, $dumps_disk|1 xfs keep /srv/backups/dumps/ongoing"

log "OS volume: $os_disk (PV $os_pv), dumps volume: $dumps_disk"
log "Generated recipe: $recipe"

cat > /tmp/reuse-parts-dbprov.cfg <<EOF
d-i partman/reuse_partitions_recipe string $recipe
d-i grub-installer/bootdev string $os_disk
EOF
debconf-set-selections /tmp/reuse-parts-dbprov.cfg
