#!/usr/bin/python3

import datetime
import logging
import subprocess
from tempfile import NamedTemporaryFile

RBD = "/usr/bin/rbd"
BACKY = "/usr/bin/backy2"

# These are utility functions for interacting with backy2 and/or RBD
#
#
# These first three functions are adapted from the example shell script
#  at http://backy2.com/docs/backup.html


def _initial_backup(pool, volume, expire):
    snapname = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

    logging.info("Creating initial backup of %s/%s" % (pool, volume))

    snapref = "%s/%s@%s" % (pool, volume, snapname)
    subprocess.run([RBD, "snap", "create", snapref])

    with NamedTemporaryFile() as blockdiff:
        # Capture a diff in blockdiff and then hand that over to backy for context

        subprocess.run(
            [RBD, "diff", "--whole-object", snapref, "--format=json"], stdout=blockdiff
        )
        subprocess.run(
            [
                BACKY,
                "backup",
                "-s",
                snapname,
                "-r",
                blockdiff.name,
                "rbd://%s" % snapref,
                volume,
                "-e",
                expire,
            ]
        )


def _differential_backup(pool, volume, last_snap, backy_snap_version_uid, expire):
    snapname = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

    logging.info(
        "Creating differential backup of %s/%s"
        " from rbd snapshot %s and backy2 version %s"
        % (pool, volume, last_snap, backy_snap_version_uid)
    )

    snapref = "%s/%s@%s" % (pool, volume, snapname)
    subprocess.run([RBD, "snap", "create", snapref])

    with NamedTemporaryFile(delete=False) as blockdiff:
        subprocess.run(
            [
                RBD,
                "diff",
                "--whole-object",
                snapref,
                "--from-snap",
                last_snap,
                "--format=json",
            ],
            stdout=blockdiff,
        )

        # Now that we have the diff we don't need the old snapshot.  Delete it.
        subprocess.run([RBD, "rm", "%s/%s@%s" % (pool, volume, last_snap)])

        subprocess.run(
            [
                BACKY,
                "backup",
                "-s",
                snapname,
                "-r",
                blockdiff.name,
                "-f",
                backy_snap_version_uid,
                "rbd://%s" % snapref,
                volume,
                "-e",
                expire,
            ]
        )


# determine whether or not this is the first backup of a given volume. If yes,
#  do a full backup; if no, do an incremental backup.
def backup_volume(pool, volume, live_for_days):
    expire = (
        datetime.datetime.now() + datetime.timedelta(days=live_for_days)
    ).strftime("%Y-%m-%d")

    all_snaps = subprocess.check_output([RBD, "snap", "ls", "%s/%s" % (pool, volume)])
    if not all_snaps:
        _initial_backup(pool, volume, expire)
    else:
        # Throw out the first line of output, it's a header
        snaplist = [snap.split() for snap in all_snaps.decode("utf8").splitlines()[1:]]

        # Convert first field (ID) to an int and sort.  I'm making some assumptions
        #  about what the ID can be here; the example code just sorts it as text
        #  which seems dodgy if we roll into extra digits
        snapdict = {int(snap[0]): snap[1:] for snap in snaplist}

        # Finally we can get the name of the latest snap
        last_snap = snapdict[(sorted(snapdict)[-1])][0]

        # See if we have a backup for this
        backup = subprocess.check_output([BACKY, "-ms", "ls", "-s", last_snap, volume])
        if not backup:
            logging.warning(
                "Existing rbd snapshot not found in backy2, reverting to initial backup."
            )
            _initial_backup(pool, volume, expire)
        else:
            backy_snap_version_uid = backup.split(b"|")[5]
            _differential_backup(
                pool, volume, last_snap, backy_snap_version_uid, expire
            )


# Convenience function that takes a nova VM id
def backup_vm(pool, vm, live_for_days):
    vm_disk = "%s_disk" % vm
    backup_volume(pool, vm_disk, live_for_days)


# Return all volumes stored in a given pool.
def ceph_volumes(pool):
    output = subprocess.check_output([RBD, "ls", pool])
    return [line.decode("utf8") for line in output.splitlines()]


# Convenience function for returning only VM volumes in a given pool
def ceph_vms(pool):
    volumes = ceph_volumes(pool)
    ids = []
    for volume in volumes:
        if volume.endswith("_disk"):
            ids.append(volume[: -len(b"_disk")])

    return ids


def backed_up_volumes():
    backup = subprocess.check_output([BACKY, "-ms", "ls"])
    volumes = [row.split(b"|")[1].decode("utf8") for row in backup.splitlines()]
    return list(set(volumes))


# Convenience function for returning backed up VMs, ignore other volumes
def backed_up_vms():
    volumes = backed_up_volumes()
    ids = []
    for volume in volumes:
        if volume.endswith("_disk"):
            ids.append(volume[: -len(b"_disk")])

    return ids
