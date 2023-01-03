#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
This is a wrapper around the cinder-backup API. It automates the following:

- Do full or incremental backups as appropriate
- Backup from snapshot if the volume is attached to a VM
- Block until a backup job completes
- Impose a timeout so we have some chance of noticing stuck jobs
- (--restore) Restore a specific backup to a specific cinder volume
- (--purge-older-than) Purge old backups that don't have newer dependencies

"""

import argparse
import datetime
import logging
import sys
import time
from tenacity import retry, stop_after_attempt, wait_random

import mwopenstackclients
import novaclient.exceptions


class CinderBackup(object):
    def __init__(self, osclients, volume_id, full=False, timeout=43200):
        self.volume_id = volume_id
        self.backup_id = None
        self.snapshot_id = None
        self.timeout = timeout
        self.cinderclient = osclients.cinderclient()
        self.volume = self.cinderclient.volumes.get(self.volume_id)
        self.volume_name = self.volume.name
        self.force_full = full

    def wait_for_resource_status(self, resource_id, refreshfunction, desiredstatuses):
        oldstatus = ""
        elapsed = 0
        naplength = 1

        resource = refreshfunction(resource_id)
        while resource.status not in desiredstatuses:
            if resource.status == "error":
                logging.error(
                    "Waiting for state {} but state is {}".format(
                        desiredstatuses, resource.status
                    )
                )
                raise RuntimeError(
                    "Openstack resource {} in error state.".format(resource_id)
                )

            if resource.status != oldstatus:
                oldstatus = resource.status
                logging.info(
                    "current status is {}; waiting for it to change to {}".format(
                        resource.status, desiredstatuses
                    )
                )

            time.sleep(naplength)
            elapsed += naplength

            if elapsed > self.timeout:
                # Since we don't actually check the clock, the timeout values
                #  here are a approximate. If someone determines that sub-second
                #  timeout accuracy is important we can add an actual clock read
                #  here.
                logging.info(
                    "timeout exceeded waiting for status update on %s." % resource
                )
                raise TimeoutError()

            resource = refreshfunction(resource.id)

    def restore_backup(self, backup_id):
        self.backup_id = backup_id
        logging.info(
            "Restoring volume %s from backup %s" % (self.volume.id, self.backup_id)
        )

        self.volume = self.cinderclient.volumes.get(self.volume_id)
        self.cinderclient.restores.restore(self.backup_id, self.volume_id)

        self.wait_for_resource_status(
            self.volume_id, self.cinderclient.volumes.get, ["available"]
        )

    @retry(reraise=True, stop=stop_after_attempt(9), wait=wait_random(min=5, max=15))
    def delete_volume_snapshots(self, snapshot_id, force=True):
        # Snapshots in admin project are intended to exist only during snapshot operation
        # Once the status moves to 'available', they can be safely removed
        logging.info("Deleting volume snapshot %s" % snapshot_id)
        self.cinderclient.volume_snapshots.delete(snapshot_id, force=force)
        self.snapshot_id = None
        # Give delete time to process
        time.sleep(10)

    @retry(reraise=True, stop=stop_after_attempt(9), wait=wait_random(min=5, max=15))
    def delete_backup(self, backup_id, force=False):
        self.cinderclient.backups.delete(backup_id, force=force)
        logging.info("Deleted backup %s" % backup_id)
        self.backup_id = None
        # Give delete time to process
        time.sleep(10)

    @retry(reraise=True, stop=stop_after_attempt(9), wait=wait_random(min=5, max=15))
    def purge_backups_older_than(self, days):
        # Delete backups older than 'days' days
        existing_backups = self.cinderclient.backups.list(
            search_opts={"volume_id": self.volume_id}
        )
        to_delete = {}
        for backup in existing_backups:
            created_at = datetime.datetime.strptime(
                backup.created_at, "%Y-%m-%dT%H:%M:%S.%f"
            )
            if created_at < (datetime.datetime.now() - datetime.timedelta(days=days)):
                to_delete[backup.id] = backup

        # Here is where it gets messy:
        #
        # We can tell whether or not a backup has dependent incrementals but
        # cannot tell what those incrementals are. Similarly, we can tell
        # if a backup is incremental but not what it depends on.
        #
        # So, we iterate.  Delete anything that doesn't have any dependencies, then
        # update our knowledge of each remaining backup.  At that point the set
        # of things without dependencies will have changed.  Refresh, and try again.
        # Once we make a pass where there's nothing to delete, we're done.
        delete_count = 0
        work_might_remain = True
        while work_might_remain:
            work_might_remain = False
            for id, backup in to_delete.copy().items():
                if not backup.has_dependent_backups:
                    self.delete_backup(id)
                    del to_delete[id]
                    delete_count += 1
                    work_might_remain = True

            # Refresh and locate backups that no longer have dependencies
            if work_might_remain:
                time.sleep(10)  # 1 second wasn't long enough
                for id in to_delete.keys():
                    to_delete[id] = self.cinderclient.backups.get(id)
        logging.info("Purged %d backups" % delete_count)

    @retry(reraise=True, stop=stop_after_attempt(3), wait=wait_random(min=30, max=60))
    def backup_volume(self):
        logging.info("Backup up volume %s" % self.volume.id)
        new_backup_name = f"{self.volume.name}-{datetime.datetime.now().isoformat()}"

        # First figure out if we need a full backup or not
        incremental = False
        if not self.force_full:
            existing_backups = self.cinderclient.backups.list(
                search_opts={"volume_id": self.volume_id}
            )

            # search for a non-incremental backup. If we don't find one then
            # we might have lost the original so let's do a full backup now.
            for backup in existing_backups:
                if not backup.is_incremental and backup.status == "available":
                    incremental = True
                    logging.info("Full backup is available; doing incremental backup")
                    break
        else:
            logging.info("User requested full backup")

        try:
            if self.volume.status == "available":
                logging.info("Volume is idle, no snapshot needed")
                backupjob_rec = self.cinderclient.backups.create(
                    self.volume.id, name=new_backup_name, incremental=incremental
                )
                self.backup_id = backupjob_rec.id
            elif self.volume.status == "in-use":
                logging.info("Backup up from snapshot")
                snapjob_rec = self.cinderclient.volume_snapshots.create(
                    self.volume.id, name=new_backup_name, force=True
                )
                self.snapshot_id = snapjob_rec.id
                self.wait_for_resource_status(
                    self.snapshot_id,
                    self.cinderclient.volume_snapshots.get,
                    ["available"],
                )
                logging.info("Just made snapshot %s" % self.snapshot_id)

                # The volume.id hint here allows this to be incremental
                #  even though the snapshot we used for the full backup is long gone
                if incremental:
                    logging.info(
                        "Preparing to make a backup of volume %s "
                        "using snapshot %s "
                        "named %s" % (self.volume.id, self.snapshot_id, new_backup_name)
                    )
                backupjob_rec = self.cinderclient.backups.create(
                    self.volume.id,
                    snapshot_id=self.snapshot_id,
                    name=new_backup_name,
                    incremental=incremental,
                )
                self.backup_id = backupjob_rec.id
            else:
                logging.info(
                    "volume {} ({}) is in state {} which this script can't handle."
                    " Skipping.".format(
                        self.volume_id, self.volume_name, self.volume.status
                    )
                )
                return False

            logging.info(
                "Generating backup %s (%s)" % (new_backup_name, self.backup_id)
            )
            self.wait_for_resource_status(
                self.backup_id, self.cinderclient.backups.get, ["available"]
            )

        except TimeoutError as e:
            logging.warning(
                "Timed out during backup of volume {} ({}) cleaing up...".format(
                    self.volume_id, self.volume_name
                )
            )
            self.delete_backup(self.backup_id, force=True)
            raise e
        except novaclient.exceptions.BadRequest as e:
            logging.warning(
                "Failed to backup volume {} ({}): {}".format(
                    self.volume_id, self.volume_name, e
                )
            )
            raise e
        finally:
            if self.snapshot_id:
                self.delete_volume_snapshots(self.snapshot_id)


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-cinder-volume-backup",
        description="Back up a volume using the cinder-backup service. "
        "Default to incremental backup if a full backup is available.",
    )
    argparser.add_argument(
        "--timeout",
        help="Max time allowed for backup to run, in seconds",
        type=int,
        default=43200,
    )
    argparser.add_argument("volume_id", help="id of volume to back up")

    chooseone = argparser.add_mutually_exclusive_group()
    chooseone.add_argument(
        "--restore",
        help="ID of backup to restore. This will overwrite the specified volume.",
    )
    chooseone.add_argument(
        "--purge-older-than",
        type=int,
        help="Number of days. All backups older than this will be deleted. Any backups with "
        " newer incremental dependencies are preserved.",
    )
    chooseone.add_argument(
        "--full",
        action="store_true",
        help="Run a full backup of the requested volume, even if incremental is possible",
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format="%(filename)s: %(asctime)s: %(levelname)s: %(message)s",
        level=logging.INFO,
        stream=sys.stdout,
    )

    osclients = mwopenstackclients.clients(envfile="/etc/novaadmin.yaml")
    backup = CinderBackup(
        osclients, args.volume_id, full=args.full, timeout=args.timeout
    )

    if args.restore:
        backup.restore_backup(args.restore)
    elif args.purge_older_than:
        backup.purge_backups_older_than(args.purge_older_than - 1)
    else:
        backup.backup_volume()

    exit(0)
