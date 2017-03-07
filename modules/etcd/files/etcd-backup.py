#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Manages backups for etcd.

Saves the backup in a specific directory and rotates old backups, keeping 7
of them.
'''
import argparse
import glob
import logging
from logging.handlers import SysLogHandler
import os
import shutil
import subprocess

log = logging.getLogger()
log.addHandler(SysLogHandler('/dev/log'))
log.setLevel(logging.INFO)

etcdctl = '/usr/bin/etcdctl'


def rotate_logs(cluster, backup_root, num_logs):
    backup_dir = os.path.join(
        backup_root,
        'etcd-{0}-backup'.format(cluster)
    )
    backupdir_content = glob.glob(backup_dir + '*')
    backupdirs = []
    for filepath in backupdir_content:
        if not os.path.isdir(filepath):
            continue
        suffix = filepath.split('.')[-1]
        if filepath == backup_dir or \
                (suffix is not None and suffix.isdigit()):
            backupdirs.append(filepath)
        else:
            log.debug("Discarding file %s", filepath)

    to_remove = len(backupdirs) - (num_logs)

    # Older backupdirs will be last
    backupdirs.sort()
    backupdirs.reverse()
    # Remove the older backupdirs
    if to_remove <= 0:
        log.debug('No need to remove the old backup dirs')
    else:
        for backupdir in backupdirs[:(to_remove)]:
            log.debug("Removing old backup dir %s", backupdir)
            shutil.rmtree(backupdir)

    if len(backupdirs) == 0 or backupdirs[-1] != backup_dir:
        log.info("Not rotating backups and no unrotated one present")
        return

    # Rename the other ones
    idx = max(0, to_remove)
    for backupdir in backupdirs[idx:]:
        if backupdir == backup_dir:
            base = backupdir
            suffix = '.1'
        else:
            base, current_suffix = backupdir.rsplit('.', 1)
            current = int(current_suffix)
            suffix = ".%d" % (current + 1)
        new_file = base + suffix
        log.info("moving %s => %s", backupdir, new_file)
        os.rename(backupdir, new_file)


def etcd_backup(cluster, backup_root):
    backup_dir = os.path.join(
        backup_root,
        'etcd-{0}-backup'.format(cluster)
    )
    data_dir = os.path.join('/var/lib/etcd', cluster)
    return subprocess.check_call([
        etcdctl, 'backup',
        '--data-dir', data_dir,
        '--backup-dir', backup_dir,
    ])


def main():
    parser = argparse.ArgumentParser(
        description="Create backups of an etcd instance",
    )
    parser.add_argument('cluster_name', help="Name of the cluster")
    parser.add_argument('backup_dir', help="Backup directory (full path)")
    parser.add_argument(
        '--keep', type=int, default=7,
        help="Number of old backups to keep")
    args = parser.parse_args()
    rotate_logs(args.cluster_name, args.backup_dir, args.keep)
    etcd_backup(args.cluster_name, args.backup_dir)

if __name__ == '__main__':
    main()
