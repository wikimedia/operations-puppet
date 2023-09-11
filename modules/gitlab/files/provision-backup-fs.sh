#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Provision filesystems and raid for GitLab backup volume
# GitLab backups are stored on dedicated SSDs /dev/sdc and /dev/sdd
# https://phabricator.wikimedia.org/T333674

RAID_NAME="/dev/md1"
MOUNT_POINT="/srv/gitlab-backup"

set -u
set -x

create_fs() {
  if [ ! -e $RAID_NAME ]; then
    sfdisk /dev/sdc < /opt/gitlab-backup-raid.cfg
    sfdisk /dev/sdd < /opt/gitlab-backup-raid.cfg

    mdadm --create $RAID_NAME --level=mirror --raid-devices=2 /dev/sdc1 /dev/sdd1
    mkfs.ext4 $RAID_NAME
  else
    echo "Raid $RAID_NAME already exists, skipping creation"
  fi

}

mount_fs() {
  if [ ! -d "$MOUNT_POINT" ]; then
    mkdir $MOUNT_POINT
  else
    echo "Mountpoint $MOUNT_POINT already exists, skipping creation"
  fi

  DISK_UUID=`blkid $RAID_NAME -o export | grep UUID`

  if ! grep -q "^$DISK_UUID $MOUNT_POINT " /etc/fstab ; then
    echo "$DISK_UUID $MOUNT_POINT ext4 defaults,nofail 0 0" >> /etc/fstab
  else
    echo "fstab entry for $DISK_UUID at $MOUNT_POINT already exists, skipping creation"
  fi

  if ! findmnt $MOUNT_POINT; then
    mount $MOUNT_POINT
  else
    echo "$MOUNT_POINT already mounted, skipping mount"
  fi
}

create_fs
mount_fs