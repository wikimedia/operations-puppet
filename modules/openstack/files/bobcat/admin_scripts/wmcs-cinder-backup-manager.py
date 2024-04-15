#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
Backup script that takes a list of projects and volumes via
a yaml file and then calls wmcs-cinder-volume-backup accordingly.

For any given project you can either enumerate one or more specific
voluem IDs, or specify ALL volumes:

<project2>
  Volumes:
  - <volume1ID>
    <volume2ID>
    <volume3ID>
  FREQUENCY: 1
  FULL_FREQUENCY: 7
  PURGE_AFTER: 20
<project2>
  Volumes: [ALL]

"""

import argparse
import time
import logging
import shutil
import subprocess

import yaml

import mwopenstackclients

if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-cinder-backup-manager",
        description="Back up cinder volumes according to a yaml config",
    )
    argparser.add_argument(
        "--timeout",
        help="Max time allowed for backup to run, in seconds",
        type=int,
        default=60 * 60 * 48,
    )
    argparser.add_argument(
        "--config",
        help="yaml config with a list of projects and volumes to back up",
        default="/etc/wmcs-cinder-backup-manager.yaml",
    )

    args = argparser.parse_args()
    with open(args.config, "r") as f:
        conf = yaml.safe_load(f)

    logging.basicConfig(
        format="%(filename)s: %(asctime)s: %(levelname)s: %(message)s",
        level=logging.INFO,
        filename="/var/log/backup_cinder_volumes/wmcs-cinder-backup-manager.log",
    )

    backup_tool_name = "wmcs-cinder-volume-backup"
    backup_tool = shutil.which(backup_tool_name)
    if not backup_tool:
        logging.error("Unable to locate %s" % backup_tool_name)
        exit(1)

    osclients = mwopenstackclients.clients(oscloud="novaadmin")
    total_errors = 0
    epoch_days = int(time.time() / (24 * 60 * 60))

    for project in conf:
        cinderclient = osclients.cinderclient(project=project)
        all_volumes = cinderclient.volumes.list()
        volume_ids = []
        full_frequency = int(conf[project].get("FULL_FREQUENCY", "7"))
        frequency = int(conf[project].get("FREQUENCY", "1"))

        # FULL_FREQUENCY_OFFSET lets us stagger full backups for big projects
        full_frequency_offset = int(conf[project].get("FULL_FREQUENCY_OFFSET", "0"))

        full = False
        if epoch_days % full_frequency == full_frequency_offset:
            # If it's a full backup day, then we're definitely backing up
            full = True
        elif epoch_days % frequency != 0:
            # otherwise, check frequency to see if we should skip today
            continue

        purge_after = int(conf[project].get("PURGE_AFTER", "30"))
        volumes = conf[project].get("volumes")
        if "ALL" in volumes:
            # just grab all the ids
            volume_ids = [volume.id for volume in all_volumes]
        else:
            for requested_volume in volumes:
                # support names or ids
                thisid = None
                for volume in all_volumes:
                    if volume.id == requested_volume:
                        thisid = volume.id
                        break
                    if volume.name == requested_volume:
                        thisid = volume.id
                        break
                if thisid:
                    volume_ids.append(thisid)
                else:
                    logging.warning(
                        "Unabled to find requested volume %s" % requested_volume
                    )
        if volume_ids:
            logging.info("Backing up %s in project %s" % (volume_ids, project))
            volume_dict = {volume.id: volume for volume in all_volumes}
            for volume_id in volume_ids:
                # Create today's backup
                backupargs = [backup_tool, volume_id, "--timeout", str(args.timeout)]

                # our backup nodes go OOM when doing incremental backups of large volumes
                #  due to the epic metadata overhead. For volumes that are more than 5Tb
                #  we just have to do full backups every time (and, ideally make those
                #  backups less often).
                if full or volume_dict[volume_id].size > 5000:
                    backupargs.append("--full")

                r = subprocess.call(backupargs)
                if r:
                    logging.warning("Failed to backup volume %s" % volume_id)
                    total_errors += 1
                logging.info("Purging old backups of %s" % volume_id)

                # Purge old backups
                purgeargs = [
                    backup_tool,
                    volume_id,
                    "--purge-older-than",
                    str(purge_after),
                ]
                r = subprocess.call(purgeargs)
                if r:
                    logging.warning("Failed to purge backups for volume %s" % volume_id)

    if total_errors > 0:
        logging.error("Got %d errors, see logs for details.", total_errors)
        exit(1)
