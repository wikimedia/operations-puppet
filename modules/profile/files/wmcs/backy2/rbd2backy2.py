#!/usr/bin/python3
from __future__ import annotations

import datetime
import json
import logging
import subprocess
from dataclasses import dataclass
from tempfile import NamedTemporaryFile
from typing import IO, Any, List, Optional

RBD = "/usr/bin/rbd"
BACKY = "/usr/bin/backy2"


def run_command(args: List[str], stdout: Optional[IO[Any]] = None, noop: bool = False) -> str:
    if noop:
        logging.info("NOOP: Would have run %s", args)
        return ""

    logging.debug("Running command %s", args)
    if stdout:
        result = subprocess.run(args=args, stdout=stdout)
        if result.returncode != 0:
            raise Exception(f"Command execution returned != 0:\n" f"command:{args}")

        return ""
    else:
        output = subprocess.check_output(args).decode("utf8")
        logging.debug(f"Output: {output}")
        return output


@dataclass
class TrashEntry:
    image_id: str
    image_name: str
    expired: bool
    pool: str

    @classmethod
    def from_trash_ls_data(cls, pool: str, trash_ls_data: dict[str, Any]):
        """
        Parses one line from the command:
        >> rbd trash ls --format=json -l <pool_name>

        Example of supported data:
            [
                {
                    "id": "ff8c794c3aee2e",
                    "name": "volume-6faff28f-b0db-46c9-9ca6-e613076c58f2",
                    "source": "USER",
                    "deleted_at": "Wed May 29 14:09:55 2024",
                    "status": "expired at Wed May 29 14:09:55 2024"
                }
            ]

        """
        expired = trash_ls_data["status"].startswith("expired at")
        return cls(
            image_id=trash_ls_data["id"],
            image_name=trash_ls_data["name"],
            expired=expired,
            pool=pool,
        )

    def _get_snapshots(self, noop: bool) -> list[dict[str, Any]]:
        """ "
        Example return value:
        [
            {
                "id": 2220,
                "name": "snapshot-8ea087a6-6997-41b2-928b-f0293d41e3d1",
                "size": 42949672960,
                "protected": "true",
                "timestamp": "Fri Jul 29 18:46:11 2022"
            }
        ]
        """
        snapshots_raw = run_command(
            [
                "rbd",
                "snap",
                "--format=json",
                "ls",
                f"--pool={self.pool}",
                f"--image-id={self.image_id}",
            ]
        )
        return json.loads(snapshots_raw)

    def _unprotect_snapshot(self, snapshot_name: str, noop: bool) -> None:
        run_command(
            [
                "rbd",
                "snap",
                "unprotect",
                f"--pool={self.pool}",
                f"--image-id={self.image_id}",
                f"--snap={snapshot_name}",
            ],
            noop=noop,
        )

    def _unprotect_snapshots(self, noop: bool) -> None:
        for snapshot in self._get_snapshots(noop=noop):
            # we actually get a string :/, just in case cast it too
            if str(snapshot["protected"]) == "true":
                logging.info(
                    "   Unprotecting snapshot %s for trash entry %s", snapshot["name"], self
                )
                self._unprotect_snapshot(snapshot_name=snapshot["name"], noop=noop)

    def remove(self, noop: bool) -> None:
        self._unprotect_snapshots(noop=noop)
        run_command(
            ["rbd", "snap", "purge", f"--pool={self.pool}", f"--image-id={self.image_id}"],
            noop=noop,
        )
        run_command(["rbd", "trash", "rm", f"{self.pool}/{self.image_id}"], noop=noop)


@dataclass
class RBDSnapshot:
    image: str
    snapshot: str
    pool: str
    protected: bool = False

    @classmethod
    def from_rbd_ls_line(cls, pool: str, rbd_ls_line: str):
        """
        Parses one line from the command:
        >> rbd ls -l <pool_name>

        Example of supported lines:

        009f0826-b09c-49a2-96d9-c93c690fc6b8_disk@2020-12-04T02:01:19\
            \t300 GiB\t2\texcl

        009f0826-b09c-49a2-96d9-c93c690fc6b8_disk@2020-12-04T02:01:19_cloudvirt1024\
            \t300 GiB\t2\texcl
        """
        if "@" not in rbd_ls_line:
            raise Exception(f"Unable to extract snapshot from line: {rbd_ls_line}")

        full_name = rbd_ls_line.split(maxsplit=1)[0]
        image, snapshot = full_name.split("@", 1)

        return cls(image=image, snapshot=snapshot, pool=pool)

    @classmethod
    def from_rbd_snap_ls_line(cls, pool: str, image_name: str, rbd_snap_ls_line: str):
        """
        Parses one line from the command:
        >> rbd snap ls <pool>/<image_name>

        Example of line:
            60784 2020-12-04T05:03:23 20 GiB           Fri Dec  4 05:03:23 2020
            60784 2020-12-04T05:03:23_cloudvirt1024 20 GiB           Fri Dec  4 05:03:23 2020
            60784 2020-12-04T05:03:23_cloudvirt1024 20 GiB yes       Fri Dec  4 05:03:23 2020
        """
        _, snapshot_name, _, _, protected, _ = rbd_snap_ls_line.split(maxsplit=5)
        return cls(
            image=image_name, snapshot=snapshot_name, pool=pool, protected=(protected == "yes")
        )

    @classmethod
    def create(cls, pool: str, image: str, snapshot: str, noop: bool = True) -> "RBDSnapshot":
        new_snapshot = RBDSnapshot(
            pool=pool,
            image=image,
            snapshot=snapshot,
        )
        run_command([RBD, "snap", "create", str(new_snapshot)], noop=noop)
        return new_snapshot

    def remove(self, noop: bool = True) -> None:
        args = [RBD, "snap", "remove", str(self)]
        if self.protected:
            logging.info("Snapshot %s protected, not removing" % str(self))
            return
        if noop:
            logging.info("NOOP: Would have executed %s", args)
        else:
            logging.debug(subprocess.check_output(args))

    def get_date(self) -> datetime.datetime:
        return datetime.datetime.strptime(self.snapshot, "%Y-%m-%dT%H:%M:%S")

    def __str__(self) -> str:
        return f"{self.pool}/{self.image}@{self.snapshot}"


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
            expire=(
                datetime.datetime.strptime(expire, "%Y-%m-%d %H:%M:%S")
                if expire and not expire.isspace()
                else datetime.datetime.min
            ),
        )

    @classmethod
    def create_full_backup(
        cls,
        pool: str,
        image_name: str,
        snapshot_name: str,
        expire: datetime.datetime,
        noop: bool = True,
    ):
        """
        Creates a full backup, that is:
            * rbd snapshot of an image/volume
            * backy backup

        The snapshot will be needed for later incremental backups.

        Returns the new backup.
        """
        logging.info(
            "Creating full backup of pool:%s, image_name:%s, snapshot_name:%s",
            pool,
            image_name,
            snapshot_name,
        )
        new_snapshot = RBDSnapshot.create(
            pool=pool,
            image=image_name,
            snapshot=snapshot_name,
            noop=noop,
        )
        with NamedTemporaryFile() as blockdiff:
            logging.debug(
                (
                    "Capturing a diff in blockdiff(%s) and then hand that "
                    "over to backy for context"
                ),
                blockdiff.name,
            )
            run_command(
                [
                    RBD,
                    "diff",
                    "--whole-object",
                    str(new_snapshot),
                    "--format=json",
                ],
                stdout=blockdiff,
                noop=noop,
            )
            run_command(
                [
                    BACKY,
                    "backup",
                    "--snapshot-name",
                    new_snapshot.snapshot,
                    "--rbd",
                    blockdiff.name,
                    f"rbd://{new_snapshot}",
                    image_name,
                    # this expire is to avoid getting removed when not using
                    # --force
                    "--expire",
                    expire.strftime("%Y-%m-%d %H:%M:%S"),
                    "--tag",
                    "full_backup",
                ],
                noop=noop,
            )

        backupline = run_command(
            [
                BACKY,
                "--machine-output",
                "--skip-header",
                "ls",
                "--snapshot-name",
                new_snapshot.snapshot,
                image_name,
            ],
            noop=noop,
        )
        if noop:
            # dummy object so nothing breaks in case we are in noop mode
            return cls(
                date=datetime.datetime.now(),
                name=image_name,
                snapshot_name=snapshot_name,
                size_mb=42,
                size_bytes=42 * 1024,
                uid="dummy-uuid-noop",
                valid=True,
                protected=False,
                tags=["full_backup"],
                expire=expire,
            )

        else:
            return cls.from_ls_line(ls_line=backupline.splitlines()[-1])

    @classmethod
    def create_diff_backup(
        cls,
        pool: str,
        image_name: str,
        snapshot_name: str,
        rbd_reference_snapshot: RBDSnapshot,
        backy_reference_uid: str,
        expire: datetime.datetime,
        noop: bool = True,
    ) -> "BackupEntry":
        """
        Creates a differential backup, that is:
            * Create a new snapshot
            * Dump the diff between the new and old snapshots
            * Create backup using the diff and the backup with the given UID
            * Remove the old snapshot

        We keep the new snapshot to use it as reference to create a future
        differential backup.
        """
        logging.info(
            (
                "Creating differential backup of pool:%s image_name:%s"
                " from rbd snapshot %s and backy2 version %s"
            ),
            pool,
            image_name,
            rbd_reference_snapshot,
            backy_reference_uid,
        )
        new_snapshot = RBDSnapshot.create(
            pool=pool,
            image=image_name,
            snapshot=snapshot_name,
            noop=noop,
        )
        with NamedTemporaryFile() as blockdiff:
            run_command(
                [
                    RBD,
                    "diff",
                    "--whole-object",
                    str(new_snapshot),
                    "--from-snap",
                    rbd_reference_snapshot.snapshot,
                    "--format=json",
                ],
                stdout=blockdiff,
                noop=noop,
            )

            run_command(
                [
                    BACKY,
                    "backup",
                    "--snapshot-name",
                    new_snapshot.snapshot,
                    "--rbd",
                    blockdiff.name,
                    "--from-version",
                    backy_reference_uid,
                    f"rbd://{new_snapshot}",
                    image_name,
                    # this expire is to avoid getting removed when not using
                    # --force
                    "--expire",
                    expire.strftime("%Y-%m-%d %H:%M:%S"),
                    "--tag",
                    "differential_backup",
                ],
                noop=noop,
            )

            # Now that we have the new backup we don't need the old snapshot.
            # Delete it.
            rbd_reference_snapshot.remove(noop=noop)

        backupline = run_command(
            [
                BACKY,
                "--machine-output",
                "--skip-header",
                "ls",
                "--snapshot-name",
                rbd_reference_snapshot.snapshot,
                image_name,
            ],
            noop=noop,
        )
        if noop:
            # dummy object so nothing breaks in case we are in noop mode
            return cls(
                date=datetime.datetime.now(),
                name=image_name,
                snapshot_name=snapshot_name,
                size_mb=42,
                size_bytes=42 * 1024,
                uid="dummy-uuid-noop",
                valid=True,
                protected=False,
                tags=["differential_backup"],
                expire=expire,
            )

        else:
            return cls.from_ls_line(ls_line=backupline.splitlines()[-1])

    def remove(self, noop: bool = True) -> None:
        run_command(
            [
                BACKY,
                "rm",
                # remove the backup even if it's 'too young'
                "--force",
                self.uid,
            ],
            noop=noop,
        )

    def get_snapshot(self, pool: str) -> Optional[RBDSnapshot]:
        # We can't ls just one snapshot
        raw_lines = run_command([RBD, "snap", "ls", f"{pool}/{self.name}"], noop=False)
        all_snapshots = [
            RBDSnapshot.from_rbd_snap_ls_line(
                pool=pool,
                image_name=self.name,
                rbd_snap_ls_line=line,
            )
            # skip the header
            for line in raw_lines.splitlines()[1:]
        ]
        for snapshot in all_snapshots:
            if snapshot.snapshot == self.snapshot_name:
                logging.debug(f"Found snapshot {snapshot} for backup {self}")
                return snapshot

        logging.debug(f"Did not find any snapshot for backup {self}")
        return None


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
    pool: str,
    volume: str,
    last_snap: str,
    backy_snap_version_uid: str,
    expire: str,
    noop: bool = False,
):
    snapname = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

    logging.info(
        "Creating differential backup of %s/%s"
        " from rbd snapshot %s and backy2 version %s"
        % (pool, volume, last_snap, backy_snap_version_uid)
    )

    snapref = "%s/%s@%s" % (pool, volume, snapname)
    run_command([RBD, "snap", "create", snapref], noop=noop)

    with NamedTemporaryFile() as blockdiff:
        run_command(
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
            noop=noop,
        )

        # Now that we have the diff we don't need the old snapshot.  Delete it.
        run_command(
            [RBD, "snap", "rm", "%s/%s@%s" % (pool, volume, last_snap)],
            noop=noop,
        )

        run_command(
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
            ],
            noop=noop,
        )


# determine whether or not this is the first backup of a given volume. If yes,
#  do a full backup; if no, do an incremental backup.
def backup_volume(pool, volume, live_for_days):
    expire = (datetime.datetime.now() + datetime.timedelta(days=live_for_days)).strftime("%Y-%m-%d")

    all_snaps = subprocess.check_output([RBD, "snap", "ls", "%s/%s" % (pool, volume)])
    if not all_snaps:
        _initial_backup(pool, volume, expire)
    else:
        # Throw out the first line of output, it's a header
        snaplist = [snap.split() for snap in all_snaps.decode("utf8").splitlines()[1:]]

        # Convert first field (ID) to an int and sort.  I'm making some
        # assumptions about what the ID can be here; the example code just
        # sorts it as text which seems dodgy if we roll into extra digits
        snapdict = {int(snap[0]): snap[1:] for snap in snaplist}

        # Finally we can get the name of the latest snap
        last_snap = snapdict[(sorted(snapdict)[-1])][0]

        # See if we have a backup for this
        backup = subprocess.check_output([BACKY, "-ms", "ls", "-s", last_snap, volume])
        if not backup:
            logging.warning(
                "Existing rbd snapshot not found in backy2, reverting to " "initial backup."
            )
            _initial_backup(pool, volume, expire)
        else:
            backy_snap_version_uid = backup.decode("utf-8").split("|")[5]
            _differential_backup(
                pool=pool,
                volume=volume,
                last_snap=last_snap,
                backy_snap_version_uid=backy_snap_version_uid,
                expire=expire,
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


# Convenience function for returning only particular volumes in a given pool
def ceph_named_volumes(pool, prefix="", postfix=""):
    volumes = ceph_volumes(pool)
    ids = []
    for volume in volumes:
        shortname = volume
        if prefix:
            if volume.startswith(prefix):
                shortname = shortname[len(prefix) :]  # noqa: E203
            else:
                continue

        if postfix:
            if shortname.endswith(postfix):
                shortname = shortname[: -len(postfix)]
            else:
                continue

        ids.append(shortname)

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


def get_backups():
    backup = subprocess.check_output([BACKY, "-ms", "ls"])
    return [BackupEntry.from_ls_line(ls_line.decode("utf8")) for ls_line in backup.splitlines()]


def get_snapshots_for_image(pool: str, image_name: str) -> List[RBDSnapshot]:
    raw_lines = run_command([RBD, "snap", "ls", f"{pool}/{image_name}"])
    return [
        RBDSnapshot.from_rbd_snap_ls_line(
            pool=pool,
            image_name=image_name,
            rbd_snap_ls_line=line,
        )
        # skip the header
        for line in raw_lines.splitlines()[1:]
    ]


def get_snapshots_for_pool(pool: str) -> List[RBDSnapshot]:
    raw_lines = subprocess.check_output([RBD, "ls", "-l", pool])
    return [
        RBDSnapshot.from_rbd_ls_line(pool=pool, rbd_ls_line=line.decode("utf8"))
        # skip the header
        for line in raw_lines.splitlines()[1:]
    ]


def get_trash_entries(pool: str) -> List[TrashEntry]:
    raw_lines = subprocess.check_output([RBD, "trash", "ls", "--format=json", "-l", pool])
    result_data = json.loads(raw_lines)
    return [TrashEntry.from_trash_ls_data(pool=pool, trash_ls_data=entry) for entry in result_data]
