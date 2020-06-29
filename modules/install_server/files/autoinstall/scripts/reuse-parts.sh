#!/bin/sh
#
# reuse-parts: An alternative partition management system for debian-installer, which is
# (only) capable of re-using existing partitions. It takes a recipe (format documented
# below), ensures that the existing partitions match the recipe, and sets the appropriate
# metadata for debian-installer's partman component to use the partitions as directed.
#
# Usage:
# ======
# - Install this script as /lib/partman/display.d/70reuse-parts.sh (or any number lower than
#   80manual_partitioning), and set it as executable.
# - Preseed config:
#       d-i partman-auto/method string reuse_parts
#       d-i partman/reuse_partitions_recipe string RECIPE
# - See below for recipe format
#
# Recipe format:
# ==============
# RECIPE := DEVICE_ENTRY [',' DEVICE_ENTRY ... ]
# DEVICE_ENTRY := device_path | PART_ENTRY ['|' PART_ENTRY ...]
# PART_ENTRY := partition_number filesystem ACTION mountpoint
# ACTION := format|keep|ignore
#
# Notes:
# - The device path can contain wildcards. Each wildcard must match a single device.
# - The partition number must match the existing device partitioning.
#   - Partitioning numbering follows the parted server's scheme, which doesn't list
#     extended partitions, and starts logical partitions at 5.
# - It is an error if a partition in the recipe doesn't exist on disk, and vice-versa.
# - For swap/lvm physical volume/biosboot/md raid partitions: use action 'ignore',
#   mountpoint 'none'
# - If a partition has action 'ignore', the filesystem value is not used, but it's
#   recommended to set a useful name for humans like "biosboot" for documentation purposes.
# - LVM logical volumes are treated as separate devices, and are matched via their
#   /dev/mapper/<vg>-<lv> path.
# - Actions:
#   - 'format' means create a fresh filesystem on the partition. The existing fs
#     doesn't matter.
#   - 'keep' means use the existing filesystem. The specified fs must match what's already
#     on the partition.
#   - 'ignore' means reuse-part will make no changes to this partition or its partman
#      metadata. It will therefore use the default partman behavior.
#
# Example recipe 1 (single disk, lvm)
# ===================================
#   /dev/vda|1 ext4 format /|5 linux-swap ignore none|6 lvmpv ignore none, \
#   /dev/mapper/*|1 xfs keep /srv
#
# This recipe assumes there is a single lvm vg with a single lv without caring about the
# naming of either.
#
# Matching partition scheme:
#
#   Disk /dev/vda: 55 GiB, 59055800320 bytes, 115343360 sectors
#   Device     Boot    Start       End  Sectors  Size Id Type
#   /dev/vda1  *        2048  78125055 78123008 37.3G 83 Linux
#   /dev/vda2       78127102 115341311 37214210 17.8G  5 Extended
#   /dev/vda5       78127104  93749247 15622144  7.5G 82 Linux swap / Solaris
#   /dev/vda6       93751296 115341311 21590016 10.3G 8e Linux LVM
#
#   Disk /dev/mapper/tank-data: 9 GiB, 9613344768 bytes, 18776064 sectors
#
# Example recipe 2 (2 disks, mdraid+lvm)
# ======================================
#   /dev/vda|1 biosboot ignore none|2 mdraid ignore none, \
#   /dev/vdb|1 biosboot ignore none|2 mdraid ignore none, \
#	/dev/mapper/*-root|1 ext4 format /, \
#   /dev/mapper/*-srv|1 ext4 keep /srv

# For:
# - restore_ifs: sets $IFS back to the default value
# - db_get: read a value from the debconf database
# - db_go: ask all outstanding questions
# - db_input: add a question to the d-i queue
# - db_subst: set a debconf template variable
# - basename (not really desired, as busybox does supply its own basename implementation)
# - open_dialog: Opens connection to parted server, and sends command.
# - read_line: reads a line from the parted server.
# - close_dialog: Closes connection to parted server.
. /lib/partman/lib/base.sh
# For:
# - update_all: refresh partman metadata for all partitions on all devices.
. /lib/partman/lib/recipes.sh

log() {
    logger -t reuse "$@"
}

error() {
    local tmpl
    tmpl="reuse-parts/${1:?}"; shift

    log "$@"
    db_subst "$tmpl" ERROR "$*"
    db_input critical "$tmpl"
    db_go
}

fatal() {
    error "$@"
    exit 1
}

dev_path() {
    echo "$1" | sed 's:/:=:g'
}

un_dev_path() {
    echo "$1" | sed 's:=:/:g'
}

parse_recipes() {
    local - reuse_recipe dev_recipe item first dev id
    reuse_recipe="${1:?}"; shift
    # Disable globbing in this function, as recipe devices can contain wildcards.
    set -o noglob

    IFS=,
    for dev_recipe in $reuse_recipe; do
        restore_ifs
        dev=''
        IFS='|'
        for item in $dev_recipe; do
            restore_ifs
            # Trim starting/trailing whitespace.
            first="${item# *}"
            first="${first%% *}"
            if [ -z "$dev" ]; then
                dev="$(dev_path "$first")"
                mkdir -p /tmp/reuse-parts/recipes/"$dev"
            else
                # Drop part num from the start
                set -- $item
                shift
                echo "$@" >> /tmp/reuse-parts/recipes/"$dev"/"$first"
            fi
        done
    done
}

get_part_recipe() {
    local dev_name recipe_dev part_num recipe_file
    dev_name="${1:?}"; shift
    recipe_dev="${1:?}"; shift
    part_num="${1:?}"; shift

    recipe_file="/tmp/reuse-parts/recipes/$recipe_dev/$part_num"
    if [ ! -e "$recipe_file" ]; then
        error recipe_mismatch \
            "[$dev_name] ERROR: no recipe entry for ${recipe_dev} partition $part_num"
        return 1
    fi

    read recipe_fs recipe_action recipe_mountpoint < "$recipe_file"
    # Ensure all fields are set
    if ! [ -n "$recipe_fs" -a -n "$recipe_action" -a -n "$recipe_mountpoint" ]; then
        error recipe_parse_failed \
            "[$dev_name] ERROR: recipe for $recipe_dev partition $part_num does not have all fields set: '$(cat "$recipe_file")'"
        return 1
    fi
    # Ensure there are no extra fields (which wind up as being added to the last var as extra words)
    if [ $(echo $recipe_mountpoint | wc -w) != 1 ]; then
        set -- $recipe_mountpoint
        shift # Drop the mountpoint from the output
        error recipe_parse_failed \
            "[$dev_name] ERROR: recipe for $recipe_dev partition $part_num has trailing garbage: '$*'"
        return 1
    fi
}

part_action() {
    local disk partid action fs mountpoint
    dev_name="${1:?}"; shift
    partid="${1:?}"; shift
    action="${1:?}"; shift
    fs="${1:?}"; shift
    mountpoint="${1:?}"; shift

    case "$action" in
        format)
            log "[$disk] Format $mountpoint as $fs"
            echo format > "$partid/method"
            touch "$partid/format"
            touch "$partid/formatable"
            ;;
        keep)
            log "[$disk] Keep $mountpoint as $fs"
            echo keep > "$partid/method"
            ;;
        ignore)
            return 0
            ;;
        *) error recipe_parse_failed \
            "[$disk] ERROR: unsupported recipe action '$recipe_action' (Supported: format|keep|ignore)";
            return 1
            ;;
    esac

    touch "$partid/existing"
    touch "$partid/use_filesystem"
    echo "$fs" > "$partid/filesystem"
    mkdir -p "$partid/options"
    echo "$mountpoint" > "$partid/mountpoint"
}

[ -e /tmp/reuse-parts ] && { log "Already ran, skipping"; exit 0; }
mkdir /tmp/reuse-parts

exec 2> /tmp/reuse-parts/log
# XXX(kormat): Can't use set -u, debian installer assumes it isn't set.
# E.g. their shell implementation of basename will break if the optional
# second argument is not supplied.
set -x

db_get partman-auto/method
if [ "$RET" != "reuse_parts" ]; then
    log "Skipping, partman-auto/method ($RET) != reuse_parts"
    exit 0
fi

# Create debconf templates to display errors via the d-i interface.
cat > /tmp/reuse-parts/debconf.templates <<EOF
Template: reuse-parts/recipe_parse_failed
Type: error
Description: reuse-parts: Unable to parse recipe
 \${ERROR}

Template: reuse-parts/dev_match_failed
Type: error
Description: reuse-parts: Recipe device matching failed
 \${ERROR}

Template: reuse-parts/recipe_mismatch
Type: error
Description: reuse-parts: Recipe mismatch with existing partitioning
 \${ERROR}

EOF
db_x_loadtemplatefile /tmp/reuse-parts/debconf.templates reuse-parts

db_get partman/reuse_partitions_recipe
parse_recipes "$RET"

for recipe_dir in /tmp/reuse-parts/recipes/*; do
    recipe_dev="$(basename "$recipe_dir")"
    dev_dir="$DEVICES/$recipe_dev"
    # Deliberately not quoting $dev_dir here, as it can contain wildcards.
    dev_matches=$(ls -1d $dev_dir | wc -l)
    case $dev_matches in
        0)
            fatal dev_match_failed \
                "ERROR: $recipe_dev matches zero devices $(cd "$DEVICES"; printf "\n\nAll devices:\n$(ls -1)")"
            ;;
        1) ;; # 1 match is a good number.
        *)
            fatal dev_match_failed \
                "ERROR: $recipe_dev matches more than one device $(cd "$DEVICES"; printf "\n\Matching devices:\n$(ls -1d $recipe_dev)")"
            ;;
    esac
    cd $dev_dir || fatal dev_match_failed "ERROR: $dev_dir is not a directory"
    dev_name=$(un_dev_path $(basename "$PWD"))

    ret=0
    part_count=0
    open_dialog PARTITIONS
    while { read_line num id size type fs path name; [ "$id" ]; }; do
        # libparted gives sections of free space the partition number -1. Skip these.
        [ "$num" == "-1" ] && continue
        part_count=$((part_count+1))
        get_part_recipe "$dev_name" "$recipe_dev" "$num" || { ret=1; break; }
        if [ "$fs" != "$recipe_fs" -a "$recipe_action" = "keep" ]; then
            # If we're supposed to use an existing FS, but the filesystem doesn't match
            # what we've been told, bail out.
            error recipe_mismatch "[$dev_name] ERROR: recipe fs ($recipe_fs) != preexisting fs ($fs)"
            ret=1
            break
        fi
        part_action "$dev_name" "$id" "$recipe_action" \
            "$recipe_fs" "$recipe_mountpoint" || { ret=1; break; }
    done
    close_dialog
    # We need to call close_dialog before exiting to avoid leaving the parted server
    # in an inconsistent state.
    [ $ret -eq 0 ] || exit $ret

    recipes_count=$(ls "$recipe_dir"/* | wc -l)
    if [ "$part_count" != "$recipes_count" ]; then
        fatal recipe_mismatch \
            "[$dev_name] ERROR: recipe partition count ($recipes_count) != actual partition count ($part_count)"
    fi
done

log "Running update_all"
update_all
log "update_all result: $?"
