#!/usr/bin/python3

import datetime
import logging
import subprocess
from dataclasses import dataclass
from tempfile import NamedTemporaryFile
from typing import List

RBD = "/usr/bin/rbd"
BACKY = "/usr/bin/backy2"


@dataclass
class BackupEntry:
    date: datetime.datetime
    name: str
    snapshot_name: str
    size_mb: int
    size_bytes: int
    uid: str
    valid: bool
    protected: bool
    tags: List[str]
    expire: datetime.datetime

    @classmethod
    def from_ls_line(cls, ls_line: str):
        """Parses a `backy2 -ms ls` line and creates a BackupEntry out of it.

        Expected order:
        date|name|snapshot_name|size|size_bytes|uid|valid|protected|tags|expire

        Example line:
        2020-12-14 05:57:10|ff9373de-bde3-4f09-8424-9364a066fff5_disk\
            |2020-12-14T05:57:07|5120|21474836480\
            |345b7e00-3dd1-11eb-9ebd-b02628295df0|1|0|b_daily\
            |2020-12-19 00:00:00
        """

        (
            date_ts,
            name,
            snapshot_name,
            size_mb,
            size_bytes,
            uid,
            valid,
            protected,
            tags,
            expire,
        ) = ls_line.split("|")
        return cls(
            date=datetime.datetime.strptime(date_ts, "%Y-%m-%d %H:%M:%S"),
            name=name,
            snapshot_name=snapshot_name,
            size_mb=int(size_mb),
            size_bytes=int(size_bytes),
            uid=uid,
            valid=bool(int(valid)),
            protected=bool(int(protected)),
            tags=tags.split(","),
            expire=datetime.datetime.strptime(expire, "%Y-%m-%d %H:%M:%S"),
        )

    def remove(self, noop: bool = True) -> None:
        args = [
            BACKY,
            "rm",
            # remove the backup even if it's 'too young'
            "--force",
            self.uid,
        ]
        if noop:
            logging.info("NOOP: Would have executed %s", args)
        else:
            logging.debug(subprocess.check_output(args))

    def __str__(self) -> str:
        return self.__repr__()

    def __repr__(self) -> str:
        return (
            "BackupEntry("
            f"date={self.date}, "
            f"name={self.name}, "
            f"snapshot_name={self.snapshot_name}, "
            f"size_mb={self.size_mb}, "
            f"size_bytes={self.size_bytes}, "
            f"uid={self.uid}, "
            f"valid={self.valid}, "
            f"protected={self.protected}, "
            f"tags={self.tags}, "
            f"expire={self.expire}"
            ")"
        )


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
        # Capture a diff in blockdiff and then hand that over to backy for
        # context

        subprocess.run(
            [RBD, "diff", "--whole-object", snapref, "--format=json"],
            stdout=blockdiff,
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
                "-t",
                "full_backup",
            ]
        )


def _differential_backup(
    pool, volume, last_snap, backy_snap_version_uid, expire
):
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
        subprocess.run(
            [RBD, "snap", "rm", "%s/%s@%s" % (pool, volume, last_snap)]
        )

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
                "-t",
                "differential_backup",
            ]
        )


# determine whether or not this is the first backup of a given volume. If yes,
#  do a full backup; if no, do an incremental backup.
def backup_volume(pool, volume, live_for_days):
    expire = (
        datetime.datetime.now() + datetime.timedelta(days=live_for_days)
    ).strftime("%Y-%m-%d")

    all_snaps = subprocess.check_output(
        [RBD, "snap", "ls", "%s/%s" % (pool, volume)]
    )
    if not all_snaps:
        _initial_backup(pool, volume, expire)
    else:
        # Throw out the first line of output, it's a header
        snaplist = [
            snap.split() for snap in all_snaps.decode("utf8").splitlines()[1:]
        ]

        # Convert first field (ID) to an int and sort.  I'm making some
        # assumptions about what the ID can be here; the example code just
        # sorts it as text which seems dodgy if we roll into extra digits
        snapdict = {int(snap[0]): snap[1:] for snap in snaplist}

        # Finally we can get the name of the latest snap
        last_snap = snapdict[(sorted(snapdict)[-1])][0]

        # See if we have a backup for this
        backup = subprocess.check_output(
            [BACKY, "-ms", "ls", "-s", last_snap, volume]
        )
        if not backup:
            logging.warning(
                "Existing rbd snapshot not found in backy2, reverting to "
                "initial backup."
            )
            _initial_backup(pool, volume, expire)
        else:
            backy_snap_version_uid = backup.split(b"|")[5]
            _differential_backup(
                pool, volume, last_snap, backy_snap_version_uid, expire
            )


def cleanup(noop: bool = True):
    args = [BACKY, "cleanup"]
    if noop:
        logging.info("NOOP: would have executed %s", args)
    else:
        logging.debug("%s", subprocess.check_output(args))


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
    volumes = [
        row.split(b"|")[1].decode("utf8") for row in backup.splitlines()
    ]
    return list(set(volumes))


# Convenience function for returning backed up VMs, ignore other volumes
def backed_up_vms():
    volumes = backed_up_volumes()
    ids = []
    for volume in volumes:
        if volume.endswith("_disk"):
            ids.append(volume[: -len(b"_disk")])

    return ids


def get_backups():
    backup = subprocess.check_output([BACKY, "-ms", "ls"])
    return [
        BackupEntry.from_ls_line(ls_line.decode("utf8"))
        for ls_line in backup.splitlines()
    ]
