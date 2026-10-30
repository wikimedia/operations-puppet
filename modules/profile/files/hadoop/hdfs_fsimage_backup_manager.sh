#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

# HDFS FSImage backup manager
# ===========================
# * check that the daily FSImage has been stored locally by the systemd timer `hadoop-namenode-backup-fetchimage`
# * send the resulting compressed daily backup to HDFS
# * set HDFS ownership & permissions
# * do the same for the `hdfs dfs -df /` output of the same day (df_YYYY-MM-DD.txt)
#
# The script is idempotent. If rerun on the same day, the script will override the backup on HDFS.
#
# Note: The backup image on HDFS is going to be manage by an Airflow job. (XML conversion, then deletion if needed).

echo "Running hdfs_fsimage_backup_manager as $(whoami)"

set -e
set -x

if [[ ! ( "$#" == 2 ) ]] ; then
  echo "Please pass 2 arguments to this script:"
  echo "  - backup_dir (eg: /srv/backup/hadoop/namenode)"
  echo "  - hdfs_backup_dir (eg: /wmf/data/raw/hdfs_xml_fsimage)"
  exit 1
fi

backup_dir="$1"
hdfs_backup_dir="$2"

fsimage_name="fsimage_$(date +'%Y-%m-%d').gz"  # eg: fsimage_2022-09-08.gz
fsimage="${backup_dir}/${fsimage_name}"  # /srv/backup/hadoop/namenode/fsimage_2022-09-08.gz
hdfs_fsimage="${hdfs_backup_dir}/${fsimage_name}"  # /wmf/data/raw/hdfs_xml_fsimage/fsimage_2022-09-08.gz

# Check the FSImage is stored locally
if [[ -f "${fsimage}" ]]; then
    echo "FSImage is present at ${fsimage}"
else
    echo "Missing local fsimage backup at ${fsimage}."
    echo "  Check status of systemd: hadoop-namenode-backup-fetchimage ."
    echo "  And mind that backups are kept locally for a limited period of time."
    echo "  Lookup \`profile::hadoop::backup::namenode::fsimage_retention_days\` for more details."
    exit 1
fi

# Send local backup to HDFS
echo "Putting to HDFS: ${hdfs_fsimage}"
if /usr/bin/hdfs dfs -test -e "${hdfs_fsimage}" ; then
    echo "  File present. Overriding."
fi
/usr/bin/hdfs dfs -put -f "${fsimage}" "${hdfs_fsimage}"

# Change ownership of the HDFS backup
ownership="analytics:analytics-admins"
echo "Setting ownership to: ${ownership} 750"
/usr/bin/hdfs dfs -chown "${ownership}" "${hdfs_fsimage}"
/usr/bin/hdfs dfs -chmod 750 "${hdfs_fsimage}"

# Send the HDFS capacity of the same day. Do it after the FSImage, so a missing file does not block the FSImage.
df_name="df_$(date +'%Y-%m-%d').txt"  # eg: df_2022-09-08.txt
df="${backup_dir}/${df_name}"
hdfs_df="${hdfs_backup_dir}/${df_name}"
if [[ ! -s "${df}" ]]; then
    echo "Missing or empty local HDFS capacity file at ${df}."
    echo "  Check status of systemd: hadoop-namenode-backup-fetchimage ."
    exit 1
fi
echo "Putting to HDFS: ${hdfs_df}"
/usr/bin/hdfs dfs -put -f "${df}" "${hdfs_df}"
/usr/bin/hdfs dfs -chown "${ownership}" "${hdfs_df}"
/usr/bin/hdfs dfs -chmod 750 "${hdfs_df}"

set +x

echo 'Done.'
