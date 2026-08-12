#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# Generates the partman/reuse_partitions_recipe for analytics Hadoop worker
# hosts with 12 JBOD data disks and an LVM OS disk (T434494).
#
# /dev/sdX names are assigned asynchronously by the kernel and are not stable
# across boots, so a static recipe keyed on device names (with the OS disk as
# /dev/sda) no longer works. Instead:
#
# - The OS disk is detected as the disk holding the physical volume of the
#   "<hostname>-vg" volume group.
# - Every other sd disk is a Hadoop JBOD data disk. Its mountpoint letter is
#   read from the "hadoop-<letter>" ext4 filesystem label that the
#   sre.hadoop.init-hadoop-workers cookbook set at creation time, so each
#   disk keeps its historical /var/lib/hadoop/data/<letter> mountpoint.
# - Any disk without a hadoop-* label aborts the install, protecting the
#   data disks from being formatted.
#
# Only /boot (partition 1 of the OS disk) and the root logical volume are
# formatted. All data disk filesystems are kept, as is the journalnode
# logical volume where present. grub-installer/bootdev is pointed at the
# detected OS disk, overriding the /dev/sda default from common.cfg.

set -e

EXPECTED_DATA_DISKS=12

log() {
    logger -t reuse-parts-hadoop-worker "$@"
    echo "reuse-parts-hadoop-worker: $*" >&2
}

vg="$(hostname)-vg"
os_pv=$(pvs --noheadings -o pv_name,vg_name | awk -v vg="$vg" '$2 == vg {print $1}')
if [ -z "$os_pv" ]; then
    log "ERROR: no physical volume found for volume group $vg. pvs reports: $(pvs 2>&1)"
    exit 1
fi
if [ "$(echo "$os_pv" | wc -w)" -ne 1 ]; then
    log "ERROR: expected exactly one physical volume in $vg, found: $os_pv"
    exit 1
fi

# e.g. /dev/sdk5 -> disk /dev/sdk, partition number 5
os_pv_partnum=$(echo "$os_pv" | sed 's/^.*[^0-9]//')
if [ -z "$os_pv_partnum" ]; then
    log "ERROR: unable to determine partition number of physical volume $os_pv"
    exit 1
fi
os_disk=${os_pv%"$os_pv_partnum"}

recipe="$os_disk|1 ext4 format /boot|$os_pv_partnum lvmpv ignore none"
num_data_disks=0
seen_letters=''
for sysdev in /sys/block/sd*; do
    disk="/dev/$(basename "$sysdev")"
    [ "$disk" = "$os_disk" ] && continue
    label=$(blkid -o value -s LABEL "${disk}1" 2>/dev/null || true)
    case "$label" in
        hadoop-[a-z])
            letter=${label#hadoop-}
            ;;
        *)
            log "ERROR: no hadoop-<letter> filesystem label on ${disk}1 (found '$label'), refusing to continue"
            exit 1
            ;;
    esac
    case " $seen_letters " in
        *" $letter "*)
            log "ERROR: filesystem label $label is not unique, refusing to continue"
            exit 1
            ;;
    esac
    seen_letters="$seen_letters $letter"
    num_data_disks=$((num_data_disks + 1))
    recipe="$recipe, $disk|1 ext4 keep /var/lib/hadoop/data/$letter"
done

if [ "$num_data_disks" -ne "$EXPECTED_DATA_DISKS" ]; then
    log "ERROR: expected $EXPECTED_DATA_DISKS data disks besides OS disk $os_disk, found $num_data_disks (letters:$seen_letters)"
    exit 1
fi

recipe="$recipe, /dev/mapper/*-root|1 ext4 format /"
if ! lv_names=$(lvs --noheadings -o lv_name "$vg" 2>&1); then
    log "ERROR: unable to list logical volumes in $vg: $lv_names"
    exit 1
fi
if echo "$lv_names" | grep -qw journalnode; then
    recipe="$recipe, /dev/mapper/*-journalnode|1 ext4 keep /var/lib/hadoop/journal"
fi
recipe="$recipe, /dev/mapper/*-swap|1 swap ignore none"

log "OS disk: $os_disk (PV $os_pv), data disk letters:$seen_letters"
log "Generated recipe: $recipe"

cat > /tmp/reuse-parts-hadoop-worker.cfg <<EOF
d-i partman/reuse_partitions_recipe string $recipe
d-i grub-installer/bootdev string $os_disk
EOF
debconf-set-selections /tmp/reuse-parts-hadoop-worker.cfg
