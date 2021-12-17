#!/usr/bin/python3
"""
This is a wrapper around the cinder-backup API. It automates the following:

- Do full or incremental backups as appropriate
- Backup from snapshot if the volume is attached to a VM
- Block until a backup job completes
- Impose a timeout so we have some chance of noticing stuck jobs

"""

import argparse
from datetime import datetime
import logging
import sys
import time

import mwopenstackclients
import novaclient.exceptions


class CinderBackup(object):
    def __init__(self, osclients, volume_id, timeout=43200):
        self.volume_id = volume_id
        self.backup_id = None
        self.snapshot_id = None
        self.timeout = timeout
        self.cinderclient = osclients.cinderclient()
        self.volume = self.cinderclient.volumes.get(self.volume_id)
        self.volume_name = self.volume.name

    def wait_for_resource_status(self, resource_id, refreshfunction, desiredstatuses):
        oldstatus = ""
        elapsed = 0
        naplength = 1

        resource = refreshfunction(resource_id)
        while resource.status not in desiredstatuses:
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

    def backup_volume(self):
        logging.info("Backup up volume %s" % self.volume.id)

        # First figure out if we need a full backup or not
        incremental = False
        existing_backups = self.cinderclient.backups.list(
            search_opts={"volume_id": self.volume_id}
        )

        # search for a non-incremental backup. If we don't find one then
        # we might have lost the original so let's do a full backup now.
        new_backup_name = f"{self.volume.name}-{datetime.now().isoformat()}"
        for backup in existing_backups:
            if not backup.is_incremental:
                incremental = True
                break
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
            self.cinderclient.backups.delete(self.backup_id, force=True)

            # Give that delete time to process; if we proceed immediately
            #  then we race with the snapshot deletion
            time.sleep(10)

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
                logging.info("Cleaning up snapshot %s" % self.snapshot_id)
                self.cinderclient.volume_snapshots.delete(self.snapshot_id, force=True)
                self.snapshot_id = None


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-cinder-volume-backup",
        description="Back up a volume using the cinder-backup service",
    )
    argparser.add_argument(
        "--timeout",
        help="Max time allowed for backup to run, in seconds",
        type=int,
        default=43200,
    )
    argparser.add_argument(
        "--restore",
        help="ID of backup to restore. This will overwrite the specified volume.",
    )
    argparser.add_argument("volume_id", help="id of volume to back up")

    args = argparser.parse_args()

    logging.basicConfig(
        format="%(filename)s: %(asctime)s: %(levelname)s: %(message)s",
        level=logging.INFO,
        stream=sys.stdout,
    )

    osclients = mwopenstackclients.clients(envfile='/etc/novaadmin.yaml')
    backup = CinderBackup(osclients, args.volume_id, args.timeout)

    if args.restore:
        backup.restore_backup(args.restore)
    else:
        backup.backup_volume()

    exit(0)
