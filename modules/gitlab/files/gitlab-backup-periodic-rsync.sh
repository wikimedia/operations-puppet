#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

backup_type=$1
backup_dir=$2
backup_destination_host=$3

if [ ! -d ${backup_dir} ];
then
  echo "Backup directory ${backup_dir} should be a directory but isn't"
  exit 1
elif [ -z ${backup_destination_host} ];
then
  echo "Backup destination host ${backup_destination_host} should be set, but isn't"
  echo "This script should be run as:"
  echo "# ${0} [BACKUP_TYPE] [BACKUP_DIR] [DESTINTION_HOST]"
  exit 1
fi

case "${backup_type}" in
  "data")
    /usr/bin/rsync -avp --delete \
      --exclude='gitlab_config_*.tar' \
      --exclude='failover_gitlab_backup.tar' \
      --include='*_gitlab_backup.tar' \
      --exclude='*' \
      ${backup_dir}/ \
      "rsync://${backup_destination_host}/data-backup"
    ;;
  "config")
    /usr/bin/rsync -avp --delete \
      --exclude='*.sh' \
      --exclude='*_gitlab_backup.tar' \
      --exclude='failover_gitlab_backup.tar' \
      ${backup_dir}/ \
      "rsync://${backup_destination_host}/data-backup"
    ;;
  *)
    echo 'Backup type should either be "config" or "data"'
    exit 1
    ;;
esac