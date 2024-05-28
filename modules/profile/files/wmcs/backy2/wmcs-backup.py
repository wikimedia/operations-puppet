#!/usr/bin/env python3

import argparse
import datetime
import json
import logging
import os
import re
import socket
import sys
from dataclasses import dataclass
from itertools import chain
from typing import Any, ClassVar, Dict, List, Optional, Set, Tuple

import mwopenstackclients
import yaml
from rbd2backy2 import (
    BackupEntry,
    RBDSnapshot,
    ceph_named_volumes,
    cleanup,
    get_backups,
    get_snapshots_for_image,
)

# This holds cached openstack information
IMAGES_CACHE_FILE = "./backups.images.cache"
INSTANCES_CACHE_FILE = "./backups.instances.cache"
VOLUMES_CACHE_FILE = "./backups.volumes.cache"
RED = "\033[91m"
GREEN = "\033[92m"
END = "\033[0m"
BOLD = "\033[1m"

Regex = str


def red(mystr: str) -> str:
    return RED + mystr + END


def green(mystr: str) -> str:
    return GREEN + mystr + END


def bold(mystr: str) -> str:
    return BOLD + mystr + END


def indent_lines(lines: str) -> str:
    return "\n".join(("    " + line) for line in lines.splitlines())


@dataclass
class MinimalConfig:
    ceph_pool: str
    config_file: str
    ceph_pool: str
    live_for_days: int
    CONFIG_FILE: ClassVar[str] = "/etc/wmcs_backup_instances.yaml"

    @classmethod
    def from_file(cls, config_file: Optional[str] = None):
        if config_file is None:
            config_file = cls.CONFIG_FILE

        with open(config_file) as f:
            config = yaml.safe_load(f)

        config["config_file"] = config_file
        return cls(**config)


@dataclass
class InstanceBackupsConfig(MinimalConfig):
    exclude_servers: Dict[str, List[Regex]]
    # project name | ALLOTHERS -> hostname
    project_assignments: Dict[str, str]
    CONFIG_FILE: ClassVar[str] = "/etc/wmcs_backup_instances.yaml"

    def get_host_for_project(self, project: str) -> str:
        return self.project_assignments.get(
            project, self.project_assignments.get("ALLOTHERS", None)
        )

    def get_host_for_vm(self, project: str, vm_name: Optional[str] = None) -> str:
        if vm_name is not None:
            for vm_regex in self.exclude_servers.get(project, []):
                if re.match(vm_regex, vm_name):
                    # maybe raise an exception instead
                    return f"excluded_from_backups (matches {vm_regex})"

        return self.get_host_for_project(project=project)


@dataclass
class ImageBackupsConfig(MinimalConfig):
    CONFIG_FILE: ClassVar[str] = "/etc/wmcs_backup_images.yaml"

    # Backup everything everywhere
    def get_host_for_image(self, project: str, image_info: Optional[Dict[str, Any]] = None) -> str:
        return socket.gethostname()


@dataclass
class VolumeBackupsConfig(MinimalConfig):
    exclude_volumes: Dict[str, List[Regex]]
    project_assignments: Dict[str, str]
    CONFIG_FILE: ClassVar[str] = "/etc/wmcs_backup_volumes.yaml"

    def get_host_for_project(self, project: str) -> str:
        return self.project_assignments.get(
            project, self.project_assignments.get("ALLOTHERS", None)
        )

    def get_host_for_image(self, project: str, image_info: Dict[str, Any]) -> str:
        if image_info is not None:
            for volume_regex in self.exclude_volumes.get(project, []):
                image_name = image_info.get("name")
                if re.match(volume_regex, image_name):
                    return f"excluded_from_backups ({volume_regex} matches {image_name})"

        return self.get_host_for_project(project=project)


@dataclass
class ImageBackup:
    image_id: str
    ceph_id: str
    image_name: str
    image_info: Dict[str, Any]
    backup_entry: BackupEntry
    size_mb: int
    snapshot_entry: Optional[RBDSnapshot]
    size_percent: Optional[float] = None

    @classmethod
    def from_entry_and_images(cls, entry: BackupEntry, images: Dict[str, Dict[str, Any]]):
        ceph_id = entry.name
        image_id = entry.name.split("-", 1)[1]
        if image_id not in images:
            logging.warning("Unable to find image with id %s", image_id)

        image_dict = images.get(image_id, None)
        image_info = image_dict if image_dict is not None else {}
        return cls(
            backup_entry=entry,
            image_id=image_id,
            ceph_id=ceph_id,
            image_name=image_info.get("name", "no_name"),
            image_info=image_info,
            snapshot_entry=None,
            size_mb=entry.size_mb,
        )

    def remove(self, pool: str, noop: bool = True) -> None:
        maybe_snapshot = None
        try:
            maybe_snapshot = self.backup_entry.get_snapshot(pool=pool)
        except Exception:
            # happens when ceph stuff is not there, we want to delete the
            # backup too if that's the case
            pass
        self.backup_entry.remove(noop=noop)
        if maybe_snapshot is not None:
            maybe_snapshot.remove(noop=noop)

    @classmethod
    def create_diff_backup(
        cls,
        pool: str,
        image_id: str,
        ceph_id: str,
        image_info: Dict[str, Dict[str, Any]],
        reference_backup: "ImageBackup",
        live_for_days: int,
        noop: bool = True,
    ):
        snapshot_name = (
            datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + f"_{socket.gethostname()}"
        )
        expire_date = datetime.datetime.now() + datetime.timedelta(
            days=live_for_days,
        )

        if reference_backup.image_id != image_id:
            raise Exception(
                f"Invalid reference backup passed for image id {image_id}: " f"{reference_backup}"
            )

        new_entry = BackupEntry.create_diff_backup(
            image_name=ceph_id,
            snapshot_name=snapshot_name,
            pool=pool,
            rbd_reference_snapshot=reference_backup.backup_entry.get_snapshot(pool=pool),
            backy_reference_uid=reference_backup.backup_entry.uid,
            expire=expire_date,
            noop=noop,
        )

        return cls(
            image_id=image_id,
            ceph_id=ceph_id,
            image_name=image_info.get("name", "no_name"),
            image_info=image_info,
            backup_entry=new_entry,
            snapshot_entry=None,
            size_mb=new_entry.size_mb,
        )

    def load_snapshot(self, pool: str) -> Optional[RBDSnapshot]:
        self.snapshot = self.backup_entry.get_snapshot(pool=pool)
        return self.snapshot

    @classmethod
    def create_full_backup(
        cls,
        pool: str,
        image_id: str,
        ceph_id: str,
        image_info: Dict[str, Dict[str, Any]],
        live_for_days: int,
        noop: bool = True,
    ):
        image_name = f"{ceph_id}"
        snapshot_name = (
            datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + f"_{socket.gethostname()}"
        )
        expire_date = datetime.datetime.now() + datetime.timedelta(days=live_for_days)

        new_entry = BackupEntry.create_full_backup(
            image_name=image_name,
            snapshot_name=snapshot_name,
            pool=pool,
            expire=expire_date,
            noop=noop,
        )

        return cls(
            image_id=image_id,
            ceph_id=ceph_id,
            image_info=image_info,
            image_name=image_info.get("name", "no_name"),
            backup_entry=new_entry,
            snapshot_entry=new_entry.get_snapshot(pool=pool),
            size_mb=new_entry.size_mb,
        )

    def __str__(self) -> str:
        percent_str = f"({self.size_percent:.2f}% of total) " if self.size_percent else ""
        return (
            f"created:{self.backup_entry.date.strftime('%Y-%m-%d %H:%M:%S')} "
            f"expires:{self.backup_entry.date.strftime('%Y-%m-%d %H:%M:%S')} "
            f"{green('VALID') if self.backup_entry.valid else red('INVALID')} "
            f"{'PROTECTED' if self.backup_entry.valid else 'UNPROTECTED'} "
            f"size:{self.size_mb}MB {percent_str}"
            f"name:{self.backup_entry.name} "
            f"snapshot:{self.backup_entry.snapshot_name} "
            f"uid:{self.backup_entry.uid} "
            f"tags:{self.backup_entry.tags}"
        )


@dataclass(unsafe_hash=True)
class ImageBackups:
    backups: List[ImageBackup]
    image_id: str
    ceph_id: str
    image_name: Optional[str]
    image_info: Dict[str, Any]
    config: ImageBackupsConfig
    size_mb: int = 0
    size_percent: Optional[float] = None

    def add_backup(self, backup: ImageBackup) -> bool:
        if backup.image_id != self.image_id:
            raise Exception(
                "Invalid backup, non-matching image_id "
                f"(backup.image_id={backup.image_id}, "
                f"self.image_id={self.image_id})"
            )

        was_added = False
        if backup not in self.backups:
            self.backups.append(backup)
            was_added = True

        if was_added:
            self.size_mb += backup.backup_entry.size_mb

        return was_added

    def update_usages(self, total_size_mb: int) -> None:
        for backup in self.backups:
            backup.size_percent = backup.size_mb * 100 / total_size_mb

    def delete_expired(self, noop: bool) -> None:
        oldest_date = datetime.datetime.now() - datetime.timedelta(
            days=self.config.live_for_days,
        )
        to_delete = [backup for backup in self.backups if backup.backup_entry.date < oldest_date]

        logging.debug(
            "%sRemoving %d backups for image %s(%s)",
            "NOOP:" if noop else "",
            len(to_delete),
            self.image_name,
            self.image_id,
        )
        for backup in to_delete:
            self.remove_backup(backup=backup, noop=noop)

    def get_dangling_snapshots(self):
        """
        This returns the list of snapshots for this image that are not being
        used for backups.

        Note that we only need one snapshot for the backups for every image,
        in order to be able to get hints when doing differential backups, and
        this snapshot has to be the oldest one that has a matching backups for
        that image.
        """
        dangling_snapshots: List[RBDSnapshot] = []

        if not self.image_info:
            # If the image is gone then it won't have any snapshots!
            return []

        if self.image_info["status"] == "backing-up":
            # Avoid races and just skip this one for now. We'll get it next time.
            return []

        # Get the latest known backup with a valid snapshot
        all_snapshots_for_image = get_snapshots_for_image(
            pool=self.config.ceph_pool, image_name=self.ceph_id
        )
        last_snapshot_with_backup = None
        for backup in sorted(
            self.backups,
            key=lambda backup: backup.backup_entry.date,
            reverse=True,
        ):
            logging.debug("    Checking %s...", backup.backup_entry.snapshot_name)
            if any(
                True
                for snapshot in all_snapshots_for_image
                if snapshot.snapshot == backup.backup_entry.snapshot_name
            ):
                last_snapshot_with_backup = backup.backup_entry.get_snapshot(
                    pool=self.config.ceph_pool
                )
                break

        if last_snapshot_with_backup:
            logging.debug(
                "Got the following snapshots for image(%s): %s",
                self.backups[0].backup_entry.name,
                last_snapshot_with_backup,
            )
        else:
            logging.debug(
                ("Got no snapshots with backup for image(%s), knows " "snapshots: %s"),
                self.backups[0].backup_entry.name,
                all_snapshots_for_image,
            )

        def is_from_this_host(snapshot_name) -> bool:
            if "_" not in snapshot_name:
                # if there's no hostname, we consider it to be for this host
                return True

            return snapshot_name.endswith(f"_{socket.gethostname()}")

        # Get all the other snapshots
        for snapshot in all_snapshots_for_image:
            if last_snapshot_with_backup is None or (
                snapshot.snapshot != last_snapshot_with_backup.snapshot
                and is_from_this_host(snapshot.snapshot)
            ):
                dangling_snapshots.append(snapshot)

        return dangling_snapshots

    def create_next_backup(self, noop: bool = True) -> ImageBackup:
        """
        It also cleans up any expired backups if everything went well.
        """
        last_backup_with_snapshot = next(
            (
                backup
                for backup in sorted(
                    self.backups,
                    key=lambda backup: backup.backup_entry.date,
                    reverse=True,
                )
                if backup.backup_entry.get_snapshot(pool=self.config.ceph_pool) is not None
            ),
            None,
        )

        if last_backup_with_snapshot is None or not last_backup_with_snapshot.backup_entry.valid:
            if last_backup_with_snapshot and not last_backup_with_snapshot.backup_entry.valid:
                logging.info("Forcing a full backup as the previous one is not valid.")
            else:
                logging.info("Forcing a full backup as there's no previous one with a " "snapshot.")

            new_backup = ImageBackup.create_full_backup(
                pool=self.config.ceph_pool,
                image_id=self.image_id,
                ceph_id=self.ceph_id,
                image_info=self.image_info,
                live_for_days=self.config.live_for_days,
                noop=noop,
            )

        else:
            new_backup = ImageBackup.create_diff_backup(
                pool=self.config.ceph_pool,
                image_id=self.image_id,
                ceph_id=self.ceph_id,
                image_info=self.image_info,
                reference_backup=last_backup_with_snapshot,
                live_for_days=self.config.live_for_days,
                noop=noop,
            )

        self.add_backup(backup=new_backup)
        self.cleanup_expired_backups(noop=noop)
        return new_backup

    def cleanup_expired_backups(self, force: bool = False, noop: bool = True) -> None:
        logging.info(
            "Cleaning up expired backups for image %s(%s)",
            self.image_info.get("name", "no_name"),
            self.image_id,
        )
        last_valid_date = datetime.datetime.now() - datetime.timedelta(
            days=self.config.live_for_days
        )
        to_delete = []
        for backup in sorted(
            self.backups,
            key=lambda backup: backup.backup_entry.date,
        ):
            if backup.backup_entry.date < last_valid_date:
                if force or len(self.backups) > len(to_delete) + 1:
                    to_delete.append(backup)
                elif len(self.backups) > len(to_delete) + 1:
                    logging.warning(
                        (
                            "Skipping removal of expired backup %s(%s), as "
                            "there's no other backups and force was False."
                        ),
                        self.image_info.get("name", "no_name"),
                        self.image_id,
                    )

        for backup in to_delete:
            logging.debug("Removing expired backup %s...", backup)
            self.remove_backup(backup=backup, noop=noop)

        logging.info(
            "Cleaned up %d expired backups for image %s(%s)",
            len(to_delete),
            self.image_info.get("name", "no_name"),
            self.image_id,
        )

    def remove_backup(self, backup: ImageBackup, noop: bool = True) -> None:
        if backup in self.backups:
            self.backups.pop(self.backups.index(backup))
            self.size_mb -= backup.size_mb
            backup.remove(pool=self.config.ceph_pool, noop=noop)
        else:
            raise Exception(f"Backup {backup} is not known to {self}")

    def remove(self, noop: bool = True) -> None:
        # The list() here is to not lose our place when
        #  remove_backup changes self.backups
        for backup in list(self.backups):
            self.remove_backup(backup, noop)

    def __str__(self) -> str:
        # we don't have diff backups
        backups_strings = sorted(bold("FULL") + f" {entry}" for entry in self.backups)
        return (
            bold("Image:")
            + f" {self.image_name}(id:{self.image_id})\n"
            + f"Total Size: {self.size_mb}MB"
            + (f"\nSize percent: {self.size_percent:.2f}%" if self.size_percent else "")
            + "\nBackups:\n    "
            + "\n    ".join(backups_strings)
        )


@dataclass
class VMBackup:
    vm_id: str
    project: Optional[str]
    vm_info: Dict[str, Any]
    backup_entry: BackupEntry
    snapshot_entry: Optional[RBDSnapshot]
    size_mb: int
    size_percent: Optional[float] = None

    @classmethod
    def from_entry_and_servers(
        cls, entry: BackupEntry, servers: Dict[str, Dict[str, Any]], pool: str
    ):
        vm_id = entry.name.split("_", 1)[0]
        if vm_id not in servers:
            logging.warning("Unable to find vm with id %s", vm_id)
        server_dict = servers.get(vm_id, None)
        server_info = server_dict if server_dict is not None else {}
        return cls(
            backup_entry=entry,
            snapshot_entry=None,
            vm_id=vm_id,
            vm_info=server_info,
            project=server_info.get("tenant_id", None),
            size_mb=entry.size_mb,
        )

    @classmethod
    def create_diff_backup(
        cls,
        pool: str,
        vm_id: str,
        vm_info: Dict[str, Dict[str, Any]],
        project: str,
        reference_backup: "VMBackup",
        live_for_days: int,
        noop: bool = True,
    ):
        image_name = f"{vm_id}_disk"
        snapshot_name = (
            datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + f"_{socket.gethostname()}"
        )
        expire_date = datetime.datetime.now() + datetime.timedelta(
            days=live_for_days,
        )

        if reference_backup.vm_id != vm_id:
            raise Exception(
                "Invalid reference backup passed for vm id {vm_id}: " f"{reference_backup}"
            )

        new_entry = BackupEntry.create_diff_backup(
            image_name=image_name,
            snapshot_name=snapshot_name,
            pool=pool,
            rbd_reference_snapshot=reference_backup.backup_entry.get_snapshot(pool=pool),
            backy_reference_uid=reference_backup.backup_entry.uid,
            expire=expire_date,
            noop=noop,
        )

        return cls(
            vm_id=vm_id,
            vm_info=vm_info,
            project=project,
            backup_entry=new_entry,
            snapshot_entry=None,
            size_mb=new_entry.size_mb,
        )

    def load_snapshot(self, pool: str) -> Optional[RBDSnapshot]:
        self.snapshot = self.backup_entry.get_snapshot(pool=pool)
        return self.snapshot

    @classmethod
    def create_full_backup(
        cls,
        pool: str,
        vm_id: str,
        vm_info: Dict[str, Dict[str, Any]],
        project: str,
        live_for_days: int,
        noop: bool = True,
    ):
        image_name = f"{vm_id}_disk"
        snapshot_name = (
            datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S") + f"_{socket.gethostname()}"
        )
        expire_date = datetime.datetime.now() + datetime.timedelta(days=live_for_days)

        new_entry = BackupEntry.create_full_backup(
            image_name=image_name,
            snapshot_name=snapshot_name,
            pool=pool,
            expire=expire_date,
            noop=noop,
        )

        return cls(
            vm_id=vm_id,
            vm_info=vm_info,
            project=project,
            backup_entry=new_entry,
            snapshot_entry=new_entry.get_snapshot(pool=pool),
            size_mb=new_entry.size_mb,
        )

    def remove(self, pool: str, noop: bool = True) -> None:
        maybe_snapshot = None
        try:
            maybe_snapshot = self.backup_entry.get_snapshot(pool=pool)
        except Exception:
            # happesn when ceph stuff is not there, we want to delete the
            # backup too if that's the case
            pass
        self.backup_entry.remove(noop=noop)
        if maybe_snapshot is not None:
            maybe_snapshot.remove(noop=noop)

    def __str__(self) -> str:
        percent_str = f"({self.size_percent:.2f}% of total) " if self.size_percent else ""
        return (
            f"created:{self.backup_entry.date.strftime('%Y-%m-%d %H:%M:%S')} "
            f"expires:{self.backup_entry.date.strftime('%Y-%m-%d %H:%M:%S')} "
            f"{green('VALID') if self.backup_entry.valid else red('INVALID')} "
            f"{'PROTECTED' if self.backup_entry.valid else 'UNPROTECTED'} "
            f"size:{self.size_mb}MB {percent_str}"
            f"name:{self.backup_entry.name} "
            f"snapshot:{self.backup_entry.snapshot_name} "
            f"uid:{self.backup_entry.uid} "
            f"tags:{self.backup_entry.tags}"
        )


@dataclass(unsafe_hash=True)
class VMBackups:
    backups: List[VMBackup]
    vm_id: str
    project: Optional[str]
    vm_info: Dict[str, Any]
    config: InstanceBackupsConfig
    size_mb: int = 0
    size_percent: Optional[float] = None

    """
    The way the backups work is:

        You have an image on RBD that you want to backup.
        For the first time, you create a snapshot, and do a backup of it (full
        backup).

        The second time, as most of the blocks are already backed up, we can
        speed up the process and only tell backy about the new changed blocks,
        for that:
            * We create a new snapshot of the image
            * We do a diff between the previous snapshot, and the new one
            * We pass that to backy, so it will download only the changed
              blocks (needs also the id of the backup matching the previous
              snapshot)
            * We remove the old snapshot as we will use the new for future
              diffs instead

        This is what we call a differential backup, note that this backup
        contains the whole of the blocks, so we can safely remove any other
        backup and this will still be complete.

    So, summarizing, on RBD side, all we need is 1 image, and 1 snapshot per
    image (+1 temporary one while doing the diff backup).

    On backy side, we have a bunch of backups, all of them are independent and
    can be deleted/restored without the need for the others but in the backend,
    hidden from us, might reference the same data blocks.
    """

    def create_next_backup(self, noop: bool = True) -> VMBackup:
        """
        It also cleans up any expired backups if everything went well.
        """
        last_backup_with_snapshot = next(
            (
                backup
                for backup in sorted(
                    self.backups,
                    key=lambda backup: backup.backup_entry.date,
                    reverse=True,
                )
                if backup.backup_entry.get_snapshot(pool=self.config.ceph_pool) is not None
            ),
            None,
        )

        if last_backup_with_snapshot is None or not last_backup_with_snapshot.backup_entry.valid:
            if last_backup_with_snapshot and not last_backup_with_snapshot.backup_entry.valid:
                logging.info("Forcing a full backup as the previous one is not valid.")
            else:
                logging.info("Forcing a full backup as there's no previous one with a " "snapshot.")

            new_backup = VMBackup.create_full_backup(
                pool=self.config.ceph_pool,
                vm_id=self.vm_id,
                vm_info=self.vm_info,
                project=self.project,
                live_for_days=self.config.live_for_days,
                noop=noop,
            )

        else:
            new_backup = VMBackup.create_diff_backup(
                pool=self.config.ceph_pool,
                vm_id=self.vm_id,
                vm_info=self.vm_info,
                project=self.project,
                reference_backup=last_backup_with_snapshot,
                live_for_days=self.config.live_for_days,
                noop=noop,
            )

        self.add_backup(backup=new_backup)
        self.cleanup_expired_backups(noop=noop)
        return new_backup

    def cleanup_expired_backups(self, force: bool = False, noop: bool = True) -> None:
        logging.info(
            "Cleaning up expired backups for VM %s.%s(%s)",
            self.project,
            self.vm_info.get("name", "no_name"),
            self.vm_id,
        )
        last_valid_date = datetime.datetime.now() - datetime.timedelta(
            days=self.config.live_for_days
        )
        to_delete = []
        for backup in sorted(
            self.backups,
            key=lambda backup: backup.backup_entry.date,
        ):
            if backup.backup_entry.date < last_valid_date:
                if force or len(self.backups) > len(to_delete) + 1:
                    to_delete.append(backup)
                elif len(self.backups) > len(to_delete) + 1:
                    logging.warning(
                        (
                            "Skipping removal of expired backup %s.%s(%s), as "
                            "there's no other backups and force was False."
                        ),
                        self.project,
                        self.vm_info.get("name", "no_name"),
                        self.vm_id,
                    )

        for backup in to_delete:
            logging.debug("Removing expired backup %s...", backup)
            self.remove_backup(backup=backup, noop=noop)

        logging.info(
            "Cleaned up %d expired backups for VM %s.%s(%s)",
            len(to_delete),
            self.project,
            self.vm_info.get("name", "no_name"),
            self.vm_id,
        )

    def add_backup(self, backup: VMBackup) -> bool:
        if backup.vm_id != self.vm_id:
            raise Exception(
                "Invalid backup, non-matching vm_id "
                f"(backup.vm_id={backup.vm_id}, self.vm_id={self.vm_id})"
            )

        was_added = False
        if backup not in self.backups:
            self.backups.append(backup)
            was_added = True

        if was_added:
            self.size_mb += backup.backup_entry.size_mb

        return was_added

    def update_usages(self, total_size_mb: int) -> None:
        for backup in self.backups:
            backup.size_percent = backup.size_mb * 100 / total_size_mb

    def remove(self, noop: bool = True) -> None:
        for backup in self.backups:
            backup.remove(pool=self.config.ceph_pool, noop=noop)

        self.backups = []
        self.size_mb = 0

    def remove_backup(self, backup: VMBackup, noop: bool = True) -> None:
        if backup in self.backups:
            self.backups.pop(self.backups.index(backup))
            self.size_mb -= backup.size_mb
            backup.remove(pool=self.config.ceph_pool, noop=noop)

        else:
            raise Exception(f"Backup {backup} is not known to {self}")

    def remove_invalids(self, force: bool, noop: bool = True) -> int:
        logging.info(
            "%sRemoving invalid backups for VM %s.%s(%s)",
            "NOOP:" if noop else "",
            self.project,
            self.vm_info.get("name", "no_name"),
            self.vm_id,
        )
        if not force and not any(backup for backup in self.backups if backup.backup_entry.valid):
            logging.warning(
                "Skipping VM backups for %s.%s(%s), not enough valid backups.",
                self.project,
                self.vm_info.get("name", "no_name"),
                self.vm_id,
            )
            return 0
        elif force and not any(backup for backup in self.backups if backup.backup_entry.valid):
            logging.warning(
                ("Deleting all VM backups for %s.%s(%s), none of them are " "valid."),
                self.project,
                self.vm_info.get("name", "no_name"),
                self.vm_id,
            )

        remove_count = 0
        valid_backups = [backup for backup in self.backups if backup.backup_entry.valid]
        for backup in self.backups:
            if backup.backup_entry.valid:
                continue

            old_size = backup.size_mb
            backup.remove(pool=self.config.ceph_pool, noop=noop)
            self.size_mb = self.size_mb - old_size + backup.size_mb
            remove_count += 1

        self.backups = valid_backups

        return remove_count

    def get_dangling_snapshots(self):
        """
        This returns the list of snapshots for this VM that are not being used
        for backups.

        Note that we only need one snapshot for the backups for every VM/image,
        in order to be able to get hints when doing differential backups, and
        this snapshot has to be the oldest one that has a matching backups for
        that VM/image.
        """
        dangling_snapshots: List[RBDSnapshot] = []
        vm_images: Set[str] = {vm_backup.backup_entry.name for vm_backup in self.backups}
        if len(vm_images) > 1:
            raise Exception("VMs with more than one image are not supported: " f"{self}")

        # Get the latest known backup with a valid snapshot
        all_snapshots_for_vm = get_snapshots_for_image(
            pool=self.config.ceph_pool,
            image_name=vm_images.pop(),
        )
        last_snapshot_with_backup = None
        for backup in sorted(
            self.backups,
            key=lambda backup: backup.backup_entry.date,
            reverse=True,
        ):
            logging.debug("    Checking %s...", backup.backup_entry.snapshot_name)
            if any(
                True
                for snapshot in all_snapshots_for_vm
                if snapshot.snapshot == backup.backup_entry.snapshot_name
            ):
                last_snapshot_with_backup = backup.backup_entry.get_snapshot(
                    pool=self.config.ceph_pool
                )
                break

        if last_snapshot_with_backup:
            logging.debug(
                "Got the following snapshots for vm(%s): %s",
                self.backups[0].backup_entry.name,
                last_snapshot_with_backup,
            )
        else:
            logging.debug(
                ("Got no snapshots with backup for vm(%s), knows " "snapshots: %s"),
                self.backups[0].backup_entry.name,
                all_snapshots_for_vm,
            )

        # Get all the other snapshots
        for snapshot in all_snapshots_for_vm:
            if (
                last_snapshot_with_backup is None
                or snapshot.snapshot != last_snapshot_with_backup.snapshot
            ):
                dangling_snapshots.append(snapshot)

        return dangling_snapshots

    def remove_vm_backup(self, vm_backup: VMBackup, noop: bool = True) -> None:
        if vm_backup.vm_id not in self.vm_id:
            raise Exception(
                f"The given backup is for VM {vm_backup.vm_id} but it "
                "does not match the current VM Backup: "
                f"{self.vm_id}"
            )

        if vm_backup in self.backups:
            raise Exception(f"The given backup was not found in the system:\n{vm_backup}")

        self.backups.pop(self.backups.index(vm_backup))
        vm_backup.remove(pool=self.config.ceph_pool, noop=noop)

    def __str__(self) -> str:
        backups_strings = sorted([f" {entry}" for entry in self.backups])
        return (
            bold("VM:")
            + f" {self.vm_info.get('name', 'no_name')}(id:{self.vm_id})\n"
            + f"Total Size: {self.size_mb}MB"
            + (f"\nSize percent: {self.size_percent:.2f}%" if self.size_percent else "")
            + "\nBackups:\n    "
            + "\n    ".join(backups_strings)
        )


@dataclass(unsafe_hash=True)
class ProjectBackups:
    vms_backups: Dict[str, VMBackups]
    project: Optional[str]
    config: InstanceBackupsConfig
    size_mb: int = 0
    size_percent: Optional[int] = None

    def add_vm_backup(self, backup: VMBackup, noop: bool) -> bool:
        if backup.vm_id not in self.vms_backups:
            self.vms_backups[backup.vm_id] = VMBackups(
                backups=[],
                vm_id=backup.vm_id,
                project=self.project,
                vm_info=backup.vm_info,
                config=self.config,
            )

        was_added = self.vms_backups[backup.vm_id].add_backup(backup)
        if was_added:
            self.size_mb += backup.backup_entry.size_mb

        return was_added

    def update_usages(self, total_size_mb: int) -> None:
        for vm_backups in self.vms_backups.values():
            vm_backups.size_percent = vm_backups.size_mb * 100 / total_size_mb
            vm_backups.update_usages(total_size_mb=total_size_mb)

    def __str__(self) -> str:
        return (
            bold("Project:")
            + f" {self.project}\n"
            + bold("Total Size:")
            + f" {self.size_mb}MB\n"
            + (
                (bold("Size percent:") + f" {self.size_percent:.2f}%\n")
                if self.size_percent
                else ""
            )
            + "\n".join(indent_lines(str(vm_backups)) for vm_backups in self.vms_backups.values())
        )

    def remove_invalids(self, force: bool, noop: bool):
        logging.info(
            "%sRemoving invalids for project %s",
            "NOOP:" if noop else "",
            self.project,
        )
        total_removed = 0
        for vm_backup in self.vms_backups.values():
            old_size = vm_backup.size_mb
            num_removed = vm_backup.remove_invalids(force=force, noop=noop)
            total_removed += num_removed
            self.size_mb = self.size_mb - old_size + vm_backup.size_mb

        return total_removed

    def create_vm_backup(self, vm_info: Dict[str, Dict[str, Any]], noop: bool = True) -> VMBackup:
        vm_id = vm_info["id"]
        if vm_id not in self.vms_backups:
            self.vms_backups[vm_id] = VMBackups(
                backups=[],
                vm_id=vm_id,
                vm_info=vm_info,
                project=self.project,
                config=self.config,
            )

        new_backup = self.vms_backups[vm_id].create_next_backup(noop=noop)
        self.add_vm_backup(new_backup, noop=noop)
        return new_backup

    def remove_vm_backup(self, vm_backup: VMBackup, noop: bool = True) -> None:
        if vm_backup.project != self.project:
            raise Exception(
                f"The given backup is for project {vm_backup.project} but it "
                f"does not match the current project {self.project}"
            )

        if vm_backup.vm_id not in self.vms_backups:
            raise Exception(
                f"The given backup is for VM {vm_backup.vm_id} but it "
                "does not match the current backed up VMs: "
                f"{self.vms_backups.keys()}"
            )

        project_backups = self.projects_backups[vm_backup.project]
        project_backups.remove_vm_backup(vm_backup, noop=noop)
        self.vms_backups[vm_backup.vm_id].remove(noop=noop)
        self.size_mb = self.size_mb - vm_backup.size_mb


@dataclass(unsafe_hash=True)
class InstanceBackupsState:
    projects_backups: Dict[str, ProjectBackups]
    config: InstanceBackupsConfig
    size_mb: int = 0

    def create_vm_backup(self, vm_name: str, project_name: str, noop: bool = True) -> bool:
        this_hostname = socket.gethostname()
        assigned_hostname = self.config.get_host_for_vm(project=project_name, vm_name=vm_name)
        if assigned_hostname != this_hostname:
            raise Exception(
                f"VM {vm_name} should be backed up on host "
                f"{assigned_hostname} not this host {this_hostname}."
            )

        vm_info = None
        logging.debug("Trying to find VM in locally known vms...")
        if project_name in self.projects_backups:
            project = self.projects_backups[project_name]
            for vm_backups in project.vms_backups.values():
                if vm_name == vm_backups.vm_info.get("name", "no_name"):
                    vm_info = vm_backups.vm_info
                    logging.debug("VM found locally: %s", vm_info)
                    break

        maybe_candidate = ""
        if vm_info is None:
            logging.debug("Trying to find VM in remotely known vms...")
            server_id_to_server_dict = get_servers_info(from_cache=True)
            for server_dict in server_id_to_server_dict.values():
                if vm_name == server_dict.get(
                    "name", "no_name"
                ) and project_name == server_dict.get("tenant_id", None):
                    vm_info = server_dict
                    logging.debug("VM found remotely: %s", vm_info)
                    break
                elif vm_name == server_dict.get("name", "no_name"):
                    maybe_candidate = server_dict

        if vm_info is None:
            maybe_str = f", found a similar VM:\n{maybe_candidate}" if maybe_candidate else ""
            raise Exception(f"Unknown VM {vm_name}{maybe_str}")

        if project_name not in self.projects_backups:
            self.projects_backups[project_name] = ProjectBackups(
                vms_backups={},
                project=project_name,
                config=self.config,
            )

        logging.debug("#" * 80)
        logging.info(
            "%sCreating backup for vm %s.%s(%s)",
            "NOOP:" if noop else "",
            vm_info.get("tenant_id", "no_project"),
            vm_info.get("name", "no_name"),
            vm_info["id"],
        )
        new_backup = self.projects_backups[project_name].create_vm_backup(
            vm_info=vm_info, noop=noop
        )
        self.size_mb += new_backup.size_mb
        logging.debug("#" * 80)

    def add_vm_backup(self, vm_backup: VMBackup, noop: bool) -> bool:
        """
        Returns True if it was added to the InstanceBackupsState, False if it
        was already there.
        """
        if vm_backup.project not in self.projects_backups:
            self.projects_backups[vm_backup.project] = ProjectBackups(
                vms_backups={},
                project=vm_backup.project,
                config=self.config,
            )

        was_added = self.projects_backups[vm_backup.project].add_vm_backup(vm_backup, noop=noop)
        if was_added:
            self.size_mb += vm_backup.size_mb

        return was_added

    def update_usages(self) -> None:
        for project_backups in self.projects_backups.values():
            project_backups.size_percent = project_backups.size_mb * 100 / self.size_mb
            project_backups.update_usages(total_size_mb=self.size_mb)

    def __str__(self) -> str:
        self.update_usages()
        out_str = bold(f"Total Size: {self.size_mb}MB") + "\n"
        out_str += bold(f"Number of projects: {len(self.projects_backups)}") + "\n"
        top_10_projects = "\n".join(
            list(
                f"{pb.size_percent:.2f}% - {name}"
                for name, pb in sorted(
                    self.projects_backups.items(),
                    reverse=True,
                    key=lambda x: x[1].size_mb,
                )
            )[:10]
        )
        top_10_vms = "\n".join(
            list(
                (f"{vm.size_percent:.2f}% - " f"{vm.vm_info.get('name', 'no_name')}({vm.vm_id})")
                for vm in sorted(
                    chain(
                        *list(
                            map(
                                lambda pb: pb.vms_backups.values(),
                                self.projects_backups.values(),
                            )
                        )
                    ),
                    reverse=True,
                    key=lambda vm: vm.size_mb,
                )
            )[:10]
        )
        out_str += bold("Top 10 projects by size:") + f"\n{indent_lines(top_10_projects)}" + "\n"
        out_str += bold("Top 10 VMs by size:") + f" \n{indent_lines(top_10_vms)}" + "\n"
        for project in self.projects_backups.values():
            out_str += ("#" * 75) + "\n"
            out_str += str(project) + "\n"

        out_str += ("#" * 75) + "\n"
        return out_str

    def remove_invalids(self, force: bool, noop: bool = True) -> None:
        logging.info("%sRemoving invalids", "NOOP:" if noop else "")
        total_removed = 0
        for project in self.projects_backups.values():
            old_size = project.size_mb
            num_removed = project.remove_invalids(force=force, noop=noop)
            total_removed += num_removed
            self.size_mb = self.size_mb - old_size + project.size_mb

        if total_removed > 0:
            logging.info("Cleaning up leftover backy blocks (this frees the space)...")
            cleanup(noop=noop)
        else:
            logging.info("No backups removed, skipping cleanup")

        logging.info(
            "%s %d invalid backups.",
            "Would have deleted" if noop else "Deleted",
            total_removed,
        )

    def remove_vm_backup(self, vm_backup: VMBackup, noop: bool = True) -> None:
        if vm_backup.project not in self.projects:
            raise Exception(
                f"The given backup is for project {vm_backup.project} but it "
                "does not match any of the known ones: "
                f"{self.projects_backups.keys()}"
            )

        project_backups = self.projects_backups[vm_backup.project]
        project_backups.remove_vm_backup(vm_backup, noop=noop)

    def print_dangling_snapshots(self) -> None:
        for snapshot in self.get_dangling_snapshots():
            print(str(snapshot))

    def get_dangling_snapshots(self) -> List[RBDSnapshot]:
        """
        This returns the list of snapshots for every VM that are not being
        used for backups.

        Note that we only need one snapshot for the backups for every VM, in
        order to be able to get hints when doing differential backups.

        This snapshot has to be the oldest one that has a matching backups for
        that image/vm.
        """
        dangling_snapshots = []
        for project_backups in self.projects_backups.values():
            for vm_backups in project_backups.vms_backups.values():
                dangling_snapshots.extend(vm_backups.get_dangling_snapshots())

        return dangling_snapshots

    def remove_dangling_snapshots(self, noop: bool) -> None:
        failed_snapshots = []
        to_remove = self.get_dangling_snapshots()
        for snapshot in to_remove.copy():
            logging.info(f"Removing snapshot {snapshot}...")
            try:
                if snapshot.protected:
                    logging.info("Snapshot %s protected, not removing" % str(snapshot))
                    to_remove.remove(snapshot)
                else:
                    snapshot.remove(noop=noop)
                    if noop:
                        logging.info(f"       Done, {snapshot} would have been removed")
                    else:
                        logging.info(f"       Done, {snapshot} removed")
            except Exception as error:
                logging.error(f"ERROR: failed removing snapshot {snapshot}: {error}")
                failed_snapshots.append((snapshot, error))

        logging.info(
            "Removed %d snapshots, %d failed.",
            len(to_remove) - len(failed_snapshots),
            len(failed_snapshots),
        )
        if failed_snapshots:
            sys.exit(1)

    def get_assigned_vms(self, from_cache: bool = True) -> List[Dict[str, Any]]:
        assigned_vms: List[Dict[str, Any]] = []
        this_hostname = socket.gethostname()
        server_id_to_server_dict = get_servers_info(from_cache)
        ceph_servers = ceph_named_volumes(pool=self.config.ceph_pool, postfix="_disk")
        for server_id, server_info in server_id_to_server_dict.items():
            if server_id not in ceph_servers:
                continue
            project = server_info.get("tenant_id", "no_project")
            name = server_info.get("name", "no_name")
            status = server_info.get("status", "no_status")
            if (
                this_hostname == self.config.get_host_for_vm(project=project, vm_name=name)
                and status.lower() != "build"
            ):
                assigned_vms.append(server_info)

        return assigned_vms

    def backup_assigned_vms(self, from_cache: bool = True, noop: bool = True) -> None:
        tries = 3
        for server_info in self.get_assigned_vms(from_cache):
            cur_try = 0
            vm_name = server_info.get("name", "no_name")
            vm_id = server_info.get("id", "no_id")
            project_id = server_info.get("tenant_id", "no_project")
            while cur_try < tries:
                try:
                    self.create_vm_backup(
                        vm_name=vm_name,
                        project_name=project_id,
                        noop=noop,
                    )
                    break

                except Exception as error:
                    if not vm_in_project(vm_id, project_id):
                        logging.warning(f"VM {vm_name} vanished mid-backup, skipping.")
                        break

                    logging.warning(
                        f"Got an error trying to backup {vm_name}, try "
                        f"n#{cur_try} of {tries}: {error}"
                    )
                    cur_try += 1
                    if cur_try == tries:
                        raise

    def remove_unhandled_backups(self, from_cache: bool = True, noop: bool = True) -> None:
        logging.info("%sSearching for unhandled backups...", "NOOP:" if noop else "")
        handled_vm_ids_projects: Set[Tuple[str, str]] = {
            (vm_info["id"], vm_info.get("tenant_id", "no_project"))
            for vm_info in self.get_assigned_vms(from_cache)
        }
        backups_removed = 0
        for project_backups in self.projects_backups.values():
            for vm_backups in project_backups.vms_backups.values():
                if not vm_backups.vm_id.endswith("_disk"):
                    print("Not a vm backup, skipping: %s" % vm_backups.vm_id)
                    continue
                vm_id_project = (vm_backups.vm_id, project_backups.project)
                if vm_id_project not in handled_vm_ids_projects:
                    logging.info(
                        "%sRemoving unhandled VM backups:\n%s",
                        "NOOP:" if noop else "",
                        indent_lines(str(vm_backups)),
                    )
                    backups_removed += len(vm_backups.backups)
                    vm_backups.remove(noop=noop)

        logging.info("%sRemoved %d backups.", "NOOP:" if noop else "", backups_removed)
        if backups_removed > 0:
            logging.info("Cleaning up leftover backy blocks (this frees the space)...")
            cleanup(noop=noop)
        else:
            logging.info("No backups removed, skipping cleanup")


@dataclass(unsafe_hash=True)
class ImageBackupsState:
    image_backups: Dict[str, ImageBackups]
    images_info: Dict[str, Dict[str, Any]]
    config: ImageBackupsConfig
    image_prefix: str = ""
    image_postfix: str = ""
    size_mb: int = 0

    def add_image_backup(self, image_backup: ImageBackup) -> bool:
        """
        Returns True if it was added to the ImageBackupsState, False if it
        was already there.
        """
        if image_backup.image_id not in self.image_backups:
            self.image_backups[image_backup.image_id] = ImageBackups(
                config=self.config,
                backups=[],
                image_name=image_backup.image_name,
                image_id=image_backup.image_id,
                ceph_id=image_backup.ceph_id,
                image_info=image_backup.image_info,
            )

        was_added = self.image_backups[image_backup.image_id].add_backup(image_backup)

        if was_added:
            self.size_mb += image_backup.size_mb
            return True
        else:
            return False

    def update_usages(self) -> None:
        for project_backups in self.image_backups.values():
            project_backups.size_percent = project_backups.size_mb * 100 / self.size_mb
            project_backups.update_usages(total_size_mb=self.size_mb)

    def delete_expired(self, noop: bool) -> None:
        for image_backup in self.image_backups.values():
            image_backup.delete_expired(noop=noop)
        cleanup(noop=noop)

    def print_dangling_snapshots(self) -> None:
        for snapshot in self.get_dangling_snapshots():
            print(str(snapshot))

    def get_dangling_snapshots(self) -> List[RBDSnapshot]:
        """
        This returns the list of snapshots for every image that are not being
        used for backups.

        Note that we only need one snapshot for the backups for every image, in
        order to be able to get hints when doing differential backups.

        This snapshot has to be the oldest one that has a matching backups for
        that image/vm. And it will ignore snapshots that have a diffirent
        '@<hosntname>' suffix
        """
        dangling_snapshots = []
        for image_backups in self.image_backups.values():
            dangling_snapshots.extend(image_backups.get_dangling_snapshots())

        return dangling_snapshots

    def remove_dangling_snapshots(self, noop: bool) -> None:
        failed_snapshots = []
        to_remove = self.get_dangling_snapshots()
        for snapshot in to_remove.copy():
            logging.info(f"Removing snapshot {snapshot}...")
            try:
                if snapshot.protected:
                    logging.info("Snapshot %s protected, not removing" % str(snapshot))
                    to_remove.remove(snapshot)
                else:
                    snapshot.remove(noop=noop)
                    if noop:
                        logging.info(f"       Done, {snapshot} would have been removed")
                    else:
                        logging.info(f"       Done, {snapshot} removed")
            except Exception as error:
                logging.error(f"ERROR: failed removing snapshot {snapshot}: {error}")
                failed_snapshots.append((snapshot, error))

        logging.info(
            "Removed %d snapshots, %d failed.",
            len(to_remove) - len(failed_snapshots),
            len(failed_snapshots),
        )
        if failed_snapshots:
            sys.exit(1)

    def create_image_backup(
        self, image_info: Dict[str, Any], project_name: str = None, noop: bool = True
    ) -> None:
        image_id = image_info["id"]
        if project_name:
            this_hostname = socket.gethostname()
            assigned_hostname = self.config.get_host_for_image(
                project=project_name, image_info=image_info
            )
            if assigned_hostname != this_hostname:
                raise Exception(
                    f"VM {image_id} should be backed up on host "
                    f"{assigned_hostname} not this host {this_hostname}."
                )

        logging.info(
            "%sBacking up image %s",
            "NOOP:" if noop else "",
            image_id,
        )
        if image_id not in self.image_backups:
            all_images = self.images_info
            if image_id not in all_images:
                raise Exception(
                    f"Image with ID {image_id} not found, known images:\n"
                    + "\n".join(
                        f"{info['id']}({info.get('name', 'no_name')})"
                        for info in all_images.values()
                    )
                )
            image_info = all_images[image_id]
            self.image_backups[image_id] = ImageBackups(
                config=self.config,
                backups=[],
                image_name=image_info.get("name", "no_name"),
                image_id=image_id,
                ceph_id=self.image_prefix + image_id + self.image_postfix,
                image_info=image_info,
            )
        else:
            image_info = self.image_backups[image_id].image_info

        self.image_backups[image_id].create_next_backup(noop=noop)

        logging.info(
            "%sBacked up image %s(%s)",
            "NOOP:" if noop else "",
            image_id,
            image_info.get("name", "no_name"),
        )

    def backup_all_images(self, noop: bool = True) -> None:
        all_images = self.images_info
        logging.info(
            "%sBacking up %d images...",
            "NOOP:" if noop else "",
            len(all_images),
        )
        for image_id, image_info in self.images_info.items():
            if "shelved" in image_info.get("name", "no_name"):
                # We don't want to back up shelved servers. For one thing they can't
                #  be snapshotted as far as I can see.
                logging.info(
                    "Skipping shelved instance %s %s",
                    image_id,
                    image_info.get("name", "no_name"),
                )
                continue
            self.create_image_backup(image_info=image_info, noop=noop)

        logging.info(
            "%sBacked up %d images.",
            "NOOP:" if noop else "",
            len(all_images),
        )

    def get_assigned_images(self) -> List[Dict[str, Any]]:
        assigned_images: List[Dict[str, Any]] = []
        this_hostname = socket.gethostname()
        image_id_to_image_dict = self.images_info
        ceph_vols = ceph_named_volumes(
            pool=self.config.ceph_pool, prefix=self.image_prefix, postfix=self.image_postfix
        )
        for image_id, image_info in image_id_to_image_dict.items():
            if image_id not in ceph_vols:
                continue
            project = image_info.get("os-vol-tenant-attr:tenant_id", "no_project")
            if this_hostname == self.config.get_host_for_image(
                project=project, image_info=image_info
            ):
                assigned_images.append(image_info)
        return assigned_images

    def backup_assigned_images(self, noop: bool = True) -> None:
        tries = 3
        for image_info in self.get_assigned_images():
            cur_try = 0
            image_name = image_info.get("name", "no_name")
            project_id = image_info.get("os-vol-tenant-attr:tenant_id", "no_project")
            while cur_try < tries:
                try:
                    self.create_image_backup(
                        image_info=image_info,
                        project_name=project_id,
                        noop=noop,
                    )
                    break

                except Exception as error:
                    logging.warning(
                        f"Got an error trying to backup {image_name}, try "
                        f"n#{cur_try} of {tries}: {error}"
                    )
                    cur_try += 1
                    if cur_try == tries:
                        raise

    def remove_unhandled_backups(self, from_cache: bool = True, noop: bool = True) -> None:
        logging.info("%sSearching for unhandled backups...", "NOOP:" if noop else "")
        handled_image_ids: List[str] = [
            images_info["id"] for images_info in self.get_assigned_images()
        ]
        backups_removed = 0
        for image_backups in self.image_backups.values():
            if image_backups.image_id not in handled_image_ids:
                print("Unhandled image %s" % image_backups.image_id)
                logging.info(
                    "%sRemoving unhandled image backups:\n%s",
                    "NOOP:" if noop else "",
                    indent_lines(str(image_backups)),
                )
                backups_removed += len(image_backups.backups)
                image_backups.remove(noop=noop)

        logging.info("%sRemoved %d backups.", "NOOP:" if noop else "", backups_removed)
        if backups_removed > 0:
            logging.info("Cleaning up leftover backy blocks (this frees the space)...")
            cleanup(noop=noop)
        else:
            logging.info("No backups removed, skipping cleanup")

    def __str__(self) -> str:
        self.update_usages()
        return (
            f"Total Size: {self.size_mb}MB\n"
            f"Number of images: {len(self.image_backups)}"
            "\nImage backups:\n"
            + ("\n" + "#" * 80).join(f"\n{backup}" for backup in self.image_backups.values())
            + "\n"
            + ("#" * 80)
        )


def get_servers_info(from_cache: bool) -> Dict[str, Dict[str, Any]]:
    if not from_cache or not os.path.exists(INSTANCES_CACHE_FILE):
        openstackclients = mwopenstackclients.Clients(oscloud="novaobserver")
        logging.debug("Getting instances...")
        server_id_to_server_info = {
            server.id: server.to_dict() for server in openstackclients.allinstances()
        }
        with open(INSTANCES_CACHE_FILE, "w") as cache_fd:
            cache_fd.write(json.dumps(server_id_to_server_info))

    else:
        logging.debug("Getting instances from cache...")
        server_id_to_server_info = json.load(open(INSTANCES_CACHE_FILE, "r"))

    return server_id_to_server_info


def get_images_info(from_cache: bool) -> Dict[str, Dict[str, Any]]:
    if not from_cache or not os.path.exists(IMAGES_CACHE_FILE):
        logging.debug("Getting images from the server...")
        clients = mwopenstackclients.Clients(oscloud="novaadmin")
        image_id_to_image_info = {image.id: image for image in clients.glanceclient().images.list()}
        with open(IMAGES_CACHE_FILE, "w") as cache_fd:
            logging.debug("Getting images from cache...")
            cache_fd.write(json.dumps(image_id_to_image_info))

    else:
        image_id_to_image_info = json.load(open(IMAGES_CACHE_FILE, "r"))

    return image_id_to_image_info


def get_volumes_info(from_cache: bool) -> Dict[str, Dict[str, Any]]:
    if not from_cache or not os.path.exists(VOLUMES_CACHE_FILE):
        logging.debug("Getting images from the server...")
        clients = mwopenstackclients.Clients(oscloud="novaadmin")
        volume_id_to_volume_info = {volume.id: volume.to_dict() for volume in clients.allvolumes()}
        with open(VOLUMES_CACHE_FILE, "w") as cache_fd:
            logging.debug("Writing volumes to cache...")
            cache_fd.write(json.dumps(volume_id_to_volume_info))
    else:
        volume_id_to_volume_info = json.load(open(VOLUMES_CACHE_FILE, "r"))

    return volume_id_to_volume_info


def vm_in_project(server_id: str, project_id: str) -> bool:
    """Double-check that a given VM still exists. This is useful for
    noticing when VMs have been deleted mid-backup."""
    openstackclients = mwopenstackclients.Clients(oscloud="novaobserver")
    logging.debug("Getting instances in %s...", project_id)
    server_ids = [server.id for server in openstackclients.allinstances(projectid=project_id)]
    return server_id in server_ids


# glance images and cinder volumes are approximately the same for backup purposes,
#  so we can re-use the ImageBackups* classes to manage these.
def get_current_volumes_state(from_cache: bool = False) -> ImageBackupsState:
    config = VolumeBackupsConfig.from_file()

    volume_id_to_volume_dict = get_volumes_info(from_cache)
    logging.debug("Getting backup entries...")
    backup_entries = get_backups()

    logging.debug("Creating volume summaries")
    volume_backups_state = ImageBackupsState(
        config=config,
        image_backups={},
        images_info=volume_id_to_volume_dict,
        image_prefix="volume-",
    )
    for backup_entry in backup_entries:
        volume_backups_state.add_image_backup(
            ImageBackup.from_entry_and_images(entry=backup_entry, images=volume_id_to_volume_dict)
        )
    return volume_backups_state


def get_current_images_state(from_cache: bool = False) -> ImageBackupsState:
    config = ImageBackupsConfig.from_file()

    image_id_to_image_dict = get_images_info(from_cache)
    logging.debug("Getting backup entries...")
    backup_entries = get_backups()

    logging.debug("Creating image summaries")
    image_backups_state = ImageBackupsState(
        config=config, image_backups={}, images_info=image_id_to_image_dict
    )
    for backup_entry in backup_entries:
        image_backups_state.add_image_backup(
            ImageBackup.from_entry_and_images(entry=backup_entry, images=image_id_to_image_dict)
        )
    return image_backups_state


def get_current_instances_state(
    from_cache: bool = False,
    noop: bool = True,
) -> InstanceBackupsState:
    config = InstanceBackupsConfig.from_file()
    server_id_to_server_dict = get_servers_info(from_cache)

    logging.debug("Getting backup entries...")
    backup_entries = get_backups()

    logging.debug("Creating project level summaries")
    projects_backups = InstanceBackupsState(projects_backups={}, config=config)
    for backup_entry in backup_entries:
        vm_backup = VMBackup.from_entry_and_servers(
            entry=backup_entry,
            servers=server_id_to_server_dict,
            pool=config.ceph_pool,
        )
        projects_backups.add_vm_backup(vm_backup, noop=True)

    return projects_backups


def summary(current_state: InstanceBackupsState) -> None:
    print(str(current_state))


def show_project(current_state: InstanceBackupsState, project: str) -> None:
    if project not in current_state.projects_backups:
        backup_host = current_state.config.get_host_for_vm(project=project)
        logging.warning(
            f"Project {project} not found in this host, are you sure you are "
            f"in {backup_host}? It might also be that there's no backup yet."
        )
        return

    print(("#" * 75))
    print(str(current_state.projects_backups[project]))
    print(("#" * 75))


def print_excess_backups_per_vm(current_state: InstanceBackupsState, excess: int = 3) -> None:
    for project in current_state.projects_backups.values():
        print("#" * 75 + f" {project.project}")
        for vm_backups in project.vms_backups.values():
            if len(vm_backups.backups) > 3:
                candidate_backups_strings = sorted([f"{entry}" for entry in vm_backups.backups])
                print(
                    str("\n".join(candidate_backups_strings[: len(candidate_backups_strings) - 3]))
                )

    print("#" * 75)


def _add_instances_parser(subparser: argparse.ArgumentParser) -> None:
    instances_parser = subparser.add_parser("instances", help="Handle intances backups")
    instances_subparser = instances_parser.add_subparsers()

    summary_parser = instances_subparser.add_parser("summary", help="Show a list of all backups.")
    summary_parser.set_defaults(
        func=lambda: summary(get_current_instances_state(from_cache=args.from_cache))
    )

    show_project_parser = instances_subparser.add_parser(
        "show-project",
        help="Show details of the backups of a project (in this host).",
    )
    show_project_parser.add_argument(
        "project",
        help="Project name to show info for",
    )
    show_project_parser.set_defaults(
        func=lambda: show_project(
            current_state=get_current_instances_state(from_cache=args.from_cache),
            project=args.project,
        )
    )

    show_excess_parser = instances_subparser.add_parser(
        "show-excess",
        help=(
            "Shows the backups in excess of the givent number (default 3), "
            "that is, any extra backups over that number for each VM"
        ),
    )
    show_excess_parser.add_argument("-e", "--excess", default=3, type=int)
    show_excess_parser.set_defaults(
        func=lambda: print_excess_backups_per_vm(
            get_current_instances_state(from_cache=args.from_cache)
        )
    )

    show_excess_parser = instances_subparser.add_parser(
        "remove-invalids",
        help=("Remove any invalid backups, if there's a valid one for that " "machine already."),
    )
    show_excess_parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help=(
            "If set, will remove any invalid backup even if there's no other " "backup for that VM."
        ),
    )
    show_excess_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really remove anything, just tell you what " "would be removed."),
    )
    show_excess_parser.set_defaults(
        func=lambda: get_current_instances_state(from_cache=args.from_cache).remove_invalids(
            force=args.force,
            noop=args.noop,
        )
    )

    where_parser = instances_subparser.add_parser(
        "where",
        help=(
            "Show where are stored the backups for the given project and/or "
            "VM name. Note that it might be that a specific VM is excluded "
            "from backups, pass a VM name to check if a specific VM is being "
            "backed up."
        ),
    )
    where_parser.add_argument(
        "project",
        help="Project name to look for",
    )
    where_parser.add_argument(
        "--vm",
        help="VM name to look for in specific (to see if it's excluded)",
        default=None,
    )
    where_parser.set_defaults(
        func=lambda: logging.info(
            InstanceBackupsConfig.from_file().get_host_for_vm(project=args.project, vm_name=args.vm)
        )
    )

    get_dangling_snapshots_parser = instances_subparser.add_parser(
        "get-dangling-snapshots",
        help=(
            "Get a list of the rbd snapshots that don't have a backup, for "
            "each vm backed up in this host. Note that if there's a snapshot "
            "for a vm that is not backed up in this host it will not be "
            "checked."
        ),
    )
    get_dangling_snapshots_parser.set_defaults(
        func=lambda: get_current_instances_state(
            from_cache=args.from_cache
        ).print_dangling_snapshots()
    )

    remove_dangling_snapshots_parser = instances_subparser.add_parser(
        "remove-dangling-snapshots",
        help=(
            "Get and remove the rbd snapshots that don't have a backup, for "
            "each vm backed up in this host. Note that if there's a snapshot "
            "for a vm that is not backed up in this host it will not be "
            "checked."
        ),
    )
    remove_dangling_snapshots_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really remove anything, just tell you what " "would be removed."),
    )
    remove_dangling_snapshots_parser.set_defaults(
        func=lambda: get_current_instances_state(
            from_cache=args.from_cache
        ).remove_dangling_snapshots(noop=args.noop)
    )

    backup_vm_parser = instances_subparser.add_parser(
        "backup-vm",
        help=("Trigger a backup for the given VM, removing old backups and " "snapshots if needed"),
    )
    backup_vm_parser.add_argument(
        "project_name",
        help="Project the VM is in",
    )
    backup_vm_parser.add_argument(
        "vmname",
        help="VM name to backup",
    )
    backup_vm_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    backup_vm_parser.set_defaults(
        func=lambda: get_current_instances_state(from_cache=args.from_cache).create_vm_backup(
            noop=args.noop, vm_name=args.vmname, project_name=args.project_name
        )
    )

    get_assigned_vms_parser = instances_subparser.add_parser(
        "get-assigned-vms",
        help=(
            "Show the list of vms handled by this host. Note that it only "
            "shows known VMs, if it was deleted from openstack it will not "
            "show up, though you might be able to see it's backups (without "
            "name) in the summary."
        ),
    )
    get_assigned_vms_parser.set_defaults(
        func=lambda: print(
            "\n".join(
                (f"{vm_info.get('tenant_id', 'no_project')}" f":{vm_info.get('name', 'no_name')}")
                for vm_info in get_current_instances_state(
                    from_cache=args.from_cache
                ).get_assigned_vms(from_cache=args.from_cache)
            )
        )
    )

    backup_assigned_vms_parser = instances_subparser.add_parser(
        "backup-assigned-vms",
        help="Creates a backup for each VM assigned to the host it run in.",
    )
    backup_assigned_vms_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    backup_assigned_vms_parser.set_defaults(
        func=lambda: get_current_instances_state(from_cache=args.from_cache).backup_assigned_vms(
            from_cache=args.from_cache, noop=args.noop
        )
    )

    remove_unhandled_backups_parser = instances_subparser.add_parser(
        "remove-unhandled-backups",
        help=(
            "Remove any backups that don't match any handled VM. This might "
            "happen if a machine is now backed up in another host or was "
            "deleted."
        ),
    )
    remove_unhandled_backups_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    remove_unhandled_backups_parser.set_defaults(
        func=lambda: get_current_instances_state(
            from_cache=args.from_cache
        ).remove_unhandled_backups(from_cache=args.from_cache, noop=args.noop)
    )


def _add_images_parser(subparser: argparse.ArgumentParser) -> None:
    images_parser = subparser.add_parser("images", help="Handle images backups")

    images_subparser = images_parser.add_subparsers()

    summary_parser = images_subparser.add_parser("summary", help="Show a list of all backups.")
    summary_parser.set_defaults(
        func=lambda: summary(print(str(get_current_images_state(from_cache=args.from_cache))))
    )

    delete_expired_parser = images_subparser.add_parser(
        "delete-expired", help="Delete all expired backups"
    )
    delete_expired_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    delete_expired_parser.set_defaults(
        func=lambda: summary(
            get_current_images_state(from_cache=args.from_cache).delete_expired(noop=args.noop)
        )
    )

    remove_dangling_snapshots_parser = images_subparser.add_parser(
        "remove-dangling-snapshots", help="Remave all dangling snapshots"
    )
    remove_dangling_snapshots_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    remove_dangling_snapshots_parser.set_defaults(
        func=lambda: summary(
            get_current_images_state(from_cache=args.from_cache).remove_dangling_snapshots(
                noop=args.noop
            )
        )
    )

    backup_image_parser = images_subparser.add_parser(
        "backup-image",
        help=(
            "Trigger a backup for the given image, removing old backups and " "snapshots if needed"
        ),
    )
    backup_image_parser.add_argument(
        "image_id",
        help="image id to backup",
    )
    backup_image_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    backup_image_parser.set_defaults(
        func=lambda: get_current_images_state(from_cache=args.from_cache).create_image_backup(
            noop=args.noop,
            image_info={"id": args.image_id},
        )
    )

    backup_image_parser = images_subparser.add_parser(
        "backup-all-images",
        help="Trigger a backup for all the images",
    )
    backup_image_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    backup_image_parser.set_defaults(
        func=lambda: get_current_images_state(from_cache=args.from_cache).backup_all_images(
            noop=args.noop
        )
    )


def _add_volumes_parser(subparser: argparse.ArgumentParser) -> None:
    volumes_parser = subparser.add_parser("volumes", help="Handle cinder volume backups")

    volumes_subparser = volumes_parser.add_subparsers()

    summary_parser = volumes_subparser.add_parser("summary", help="Show a list of all backups.")
    summary_parser.set_defaults(
        func=lambda: summary(print(str(get_current_volumes_state(from_cache=args.from_cache))))
    )

    delete_expired_parser = volumes_subparser.add_parser(
        "delete-expired", help="Delete all expired backups"
    )
    delete_expired_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    delete_expired_parser.set_defaults(
        func=lambda: summary(
            get_current_volumes_state(from_cache=args.from_cache).delete_expired(noop=args.noop)
        )
    )

    remove_dangling_snapshots_parser = volumes_subparser.add_parser(
        "remove-dangling-snapshots", help="Remave all dangling snapshots"
    )
    remove_dangling_snapshots_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    remove_dangling_snapshots_parser.set_defaults(
        func=lambda: summary(
            get_current_volumes_state(from_cache=args.from_cache).remove_dangling_snapshots(
                noop=args.noop
            )
        )
    )

    backup_volume_parser = volumes_subparser.add_parser(
        "backup-volume",
        help=(
            "Trigger a backup for the given volume, removing old backups and " "snapshots if needed"
        ),
    )
    backup_volume_parser.add_argument(
        "volume_id",
        help="volume id to backup",
    )
    backup_volume_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    backup_volume_parser.set_defaults(
        func=lambda: get_current_volumes_state(from_cache=args.from_cache).create_image_backup(
            noop=args.noop,
            image_info={"id": args.volume_id},
        )
    )
    get_assigned_volumes_parser = volumes_subparser.add_parser(
        "get-assigned-volumes",
        help=(
            "Show the list of volumes handled by this host. Note that it only "
            "shows known volumes, if it was deleted from openstack it will not "
            "show up, though you might be able to see it's backups (without "
            "name) in the summary."
        ),
    )
    get_assigned_volumes_parser.set_defaults(
        func=lambda: print(
            "\n".join(
                (
                    f"{volume_info.get('os-vol-tenant-attr:tenant_id', 'no_project')}"
                    f":{volume_info.get('id', 'no_id')}"
                )
                for volume_info in get_current_volumes_state(
                    from_cache=args.from_cache
                ).get_assigned_images()
            )
        )
    )
    backup_assigned_volumes_parser = volumes_subparser.add_parser(
        "backup-assigned-volumes",
        help="Creates a backup for each VM assigned to the host it run in.",
    )
    backup_assigned_volumes_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    backup_assigned_volumes_parser.set_defaults(
        func=lambda: get_current_volumes_state(from_cache=args.from_cache).backup_assigned_images(
            noop=args.noop
        )
    )

    remove_unhandled_backups_parser = volumes_subparser.add_parser(
        "remove-unhandled-backups",
        help=(
            "Remove any backups that don't match any handled volume. This might "
            "happen if a machine is now backed up in another host or was "
            "deleted."
        ),
    )
    remove_unhandled_backups_parser.add_argument(
        "-n",
        "--noop",
        action="store_true",
        help=("If set, will not really do anything, just tell you what " "would be done."),
    )
    remove_unhandled_backups_parser.set_defaults(
        func=lambda: get_current_volumes_state(from_cache=args.from_cache).remove_unhandled_backups(
            from_cache=args.from_cache, noop=args.noop
        )
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--debug", action="store_true")
    parser.add_argument(
        "--from-cache",
        action="store_true",
        help=(
            "If set, will try to load the list of servers from the cache file "
            f"({IMAGES_CACHE_FILE} for images, and {INSTANCES_CACHE_FILE} for "
            " instances) instead of doing a request to openstack."
        ),
    )
    subparser = parser.add_subparsers()
    _add_instances_parser(subparser)
    _add_images_parser(subparser)
    _add_volumes_parser(subparser)

    args = parser.parse_args()
    if args.debug:
        level = logging.DEBUG
    else:
        level = logging.INFO

    logging.basicConfig(level=level, format="%(levelname)s:[%(asctime)s] %(message)s")
    # silence some too verbose loggers
    for logger in ["novaclient", "urllib3", "keystoneauth", "keystoneclient"]:
        logging.getLogger(logger).setLevel(logging.INFO)

    args.func()
