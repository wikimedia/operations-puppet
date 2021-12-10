#!/usr/bin/python3
"""
Backup script that takes a list of projects and volumes via
a yaml file and then calls wmcs-cinder-volume-backup accordingly.

For any given project you can either enumerate one or more specific
voluem IDs, or specify ALL volumes:

<project2>
- <volume1ID>
  <volume2ID>
  <volume3ID>
<project2>
- ALL

"""

import argparse
import logging
import shutil
import subprocess
import sys
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
        default=43200,
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
        stream=sys.stdout,
    )

    backup_tool_name = "wmcs-cinder-volume-backup"
    backup_tool = shutil.which(backup_tool_name)
    if not backup_tool:
        logging.error("Unable to locate %s" % backup_tool_name)
        exit(1)

    osclients = mwopenstackclients.clients()

    for project in conf:
        cinderclient = osclients.cinderclient(project=project)
        all_volumes = cinderclient.volumes.list()
        volume_ids = []
        if "ALL" in conf[project]:
            # just grab all the ids
            volume_ids = [volume.id for volume in all_volumes]
        else:
            for requested_volume in conf[project]:
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
            for volume_id in volume_ids:
                backupargs = [backup_tool, volume_id, "--timeout", str(args.timeout)]
                r = subprocess.call(backupargs)
                if r:
                    logging.warning("Failed to backup volume %s" % volume_id)
