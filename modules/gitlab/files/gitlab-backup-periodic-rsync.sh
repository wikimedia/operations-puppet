#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

backup_type=$1
backup_dir=$2
backup_destination_host=$3

case "${backup_type}" in
  "data")
    /usr/bin/rsync -avp --delete \
      --exclude='*.sh' \
      --exclude='gitlab_config_*.tar' \
      --exclude='failover_gitlab_backup.tar' \
      "${backup_dir}/*_gitlab_backup.tar" \
      "rsync://${backup_destination_host}/data-backup"
    ;;
  "config")
    /usr/bin/rsync -avp --delete \
      --exclude='*.sh' \
      --exclude='*_gitlab_backup.tar' \
      --exclude='failover_gitlab_backup.tar' \
      "${backup_dir}/" \
      "rsync://${backup_destination_host}/data-backup"
    ;;
  *)
    echo 'Backup type should either be "config" or "data"'
    exit 1
    ;;
esac