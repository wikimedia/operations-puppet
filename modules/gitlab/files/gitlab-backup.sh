#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# GitLab backup script
# T274463
# T283076


# documentation on backing up and restoring can be found here:
# https://docs.gitlab.com/ee/raketasks/backup_restore.html

# Possible parts to SKIP are:
#
# db            Database
# uploads       Attachments
# builds        CI job output logs
# artifacts     CI job artifacts
# lfs           LFS objects
# registry      Container Registry images
# pages         Pages content
# repositories  Git repositories data + Wiki data
#
# tar           Leave backup archives in the intermediate directory, skip tar creatio

. /srv/gitlab-backup/gitlab-backup-restore-common.sh
. /srv/gitlab-backup/gitlab-backup-config.sh

lock_backups

case "$1" in
    "full")
    /usr/bin/gitlab-backup create CRON=1 STRATEGY=copy GZIP_RSYNCABLE="${RSYNCABLE_GZIP}" SKIP=builds,artifacts,registry GITLAB_BACKUP_MAX_CONCURRENCY="${MAX_CONCURRENCY}" GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY="${MAX_STORAGE_CONCURRENCY}";;
    "partial")
    /usr/bin/gitlab-backup create BACKUP=partial CRON=1 STRATEGY=copy GZIP_RSYNCABLE="${RSYNCABLE_GZIP}" SKIP=packages GITLAB_BACKUP_MAX_CONCURRENCY="${MAX_CONCURRENCY}" GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY="${MAX_STORAGE_CONCURRENCY}";;
    "config")
    /usr/bin/gitlab-ctl backup-etc;;
    "failover")
    # full backup for failover, including builds, artifacts and registry and without copy strategy
    /usr/bin/gitlab-backup create BACKUP=failover CRON=1 GZIP_RSYNCABLE="${RSYNCABLE_GZIP}" GITLAB_BACKUP_MAX_CONCURRENCY="${MAX_CONCURRENCY}" GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY="${MAX_STORAGE_CONCURRENCY}";;
    "lock")
    # This is intended for use in cookbooks and other situations where we want to create a lock file without running a backup.
    # Since the lockfile has already been created we just need to un-trap the signals so we can exit without removing the lock
    trap - SIGINT SIGHUP SIGABRT EXIT;;
    "unlock")
    unlock_backups;;
    *)
    echo "Please run script with parameter [full, partial, config, failover]"; exit 1 ;;
esac