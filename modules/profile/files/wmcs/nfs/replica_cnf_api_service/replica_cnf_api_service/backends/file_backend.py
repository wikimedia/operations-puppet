#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

import configparser
from dataclasses import dataclass
from logging import getLogger
from pathlib import Path
from typing import cast

from replica_cnf_api_service.backends.common import (
    DRY_RUN_PASSWORD,
    DRY_RUN_USERNAME,
    Backend,
    BackendError,
    Config,
    ReplicaCnf,
    Skip,
    UserType,
    run_script,
)

LOGGER = getLogger(__name__)


@dataclass
class FileConfig(Config):
    scripts_path: Path
    use_sudo: bool
    replica_cnf_path: Path


@dataclass
class ToolforgeToolBackendConfig(FileConfig):
    tools_project_prefix: str


class ToolforgeUserFileBackend(Backend):
    USER_TYPE = UserType.TOOLFORGE_USER

    def __init__(self, config: Config):
        self.config: FileConfig = cast(FileConfig, config)

    def handles_user_type(self, user_type: UserType) -> bool:
        return user_type == UserType.TOOLFORGE_USER

    def get_relative_path(self, user: str) -> Path:
        return Path(user) / "replica.my.cnf"

    def get_replica_cnf(self, user: str, user_type: UserType, dry_run: bool) -> ReplicaCnf:
        """
        Common for all the file backends
        """
        if dry_run:  # return dummy username and password if dry_run is True
            return ReplicaCnf(
                user_type=self.USER_TYPE,
                user=user,
                db_user=DRY_RUN_USERNAME,
                db_password=DRY_RUN_PASSWORD,
            )

        cp = configparser.ConfigParser()

        try:
            res = run_script(
                script="read_replica_cnf.sh",
                scripts_path=self.config.scripts_path,
                use_sudo=self.config.use_sudo,
                args=[
                    str(self.get_relative_path(user)),
                    self.USER_TYPE.value,
                ],
            )

            if res.returncode == 0:
                cp.read_string(res.stdout.decode("utf-8"))

                return ReplicaCnf(
                    user_type=self.USER_TYPE,
                    user=user,
                    # sometimes these values have quotes around them
                    db_user=cp["client"]["user"].strip("'"),
                    db_password=cp["client"]["password"].strip("'"),
                )
            else:
                raise BackendError(res.stderr.decode("utf-8"))

        except KeyError as err:  # the err variable is not descriptive enough for KeyError.
            # catch KeyError and add more context to the error response.
            raise BackendError("key {0} doesn't exist in ConfigParser".format(str(err)))

    def check_if_should_skip_write_replica_cnf(
        self, dest_path: Path, replica_cnf: ReplicaCnf
    ) -> None:
        """
        Each file backend implements it's own
        """
        if not dest_path.parent.exists():
            raise Skip(
                (
                    f"Skipping account {replica_cnf.user}: Home directory ({dest_path.parent}) does not exist yet"
                ),
                dest_path=dest_path,
            )

        if dest_path.exists():
            raise Skip(
                f"Skipping account {replica_cnf.user}: File already exists.",
                dest_path=dest_path,
            )

    def save_replica_cnf(
        self,
        replica_cnf: ReplicaCnf,
        account_uid: int,
        dry_run: bool,
    ) -> ReplicaCnf:
        """
        Common for all the file backends
        """
        dest_path = (
            self.config.replica_cnf_path / self.get_relative_path(user=replica_cnf.user)
        ).resolve()
        if dry_run:
            # do not attempt to write replica.my.cnf file to replica_path if dry_run is True
            return replica_cnf

        self.check_if_should_skip_write_replica_cnf(dest_path=dest_path, replica_cnf=replica_cnf)

        res = run_script(
            script="write_replica_cnf.sh",
            scripts_path=self.config.scripts_path,
            use_sudo=self.config.use_sudo,
            args=[
                str(account_uid),
                str(self.get_relative_path(user=replica_cnf.user)),
                replica_cnf.to_mysql_conf_str(),
                replica_cnf.user_type.value,
            ],
        )

        replica_path = Path(res.stdout.decode("utf-8").strip() or dest_path).resolve()
        if res.returncode != 0:
            if replica_path.exists():
                # cleanup if we created the file partially
                run_script(
                    script="delete_replica_cnf.sh",
                    scripts_path=self.config.scripts_path,
                    use_sudo=self.config.use_sudo,
                    args=[
                        str(self.get_relative_path(user=replica_cnf.user)),
                        replica_cnf.user_type.value,
                    ],
                )

            stderr = res.stderr.decode("utf-8")
            LOGGER.error("Failed to create conf file at %s: %s", replica_path, stderr)
            raise BackendError(f"Failed to create conf file at {replica_path}: {stderr}")

        LOGGER.info("created conf file at %s.", replica_path)
        return replica_cnf

    def delete_replica_cnf(self, user: str, user_type: UserType, dry_run: bool) -> None:
        """
        Shared among all file backends
        """
        dest_path = self.config.replica_cnf_path / self.get_relative_path(user=user)
        if dry_run:
            # do not attempt to write replica.my.cnf file to replica_path if dry_run is True
            return

        res = run_script(
            script="delete_replica_cnf.sh",
            scripts_path=self.config.scripts_path,
            use_sudo=self.config.use_sudo,
            args=[
                str(self.get_relative_path(user=user)),
                user_type.value,
            ],
        )

        if res.returncode == 0:
            return

        raise BackendError(res.stderr.decode("utf-8").strip())


class ToolforgeToolFileBackend(ToolforgeUserFileBackend):
    USER_TYPE = UserType.TOOLFORGE_TOOL

    def __init__(self, config: Config):
        self.config: ToolforgeToolBackendConfig = cast(ToolforgeToolBackendConfig, config)

    def handles_user_type(self, user_type: UserType) -> bool:
        return user_type == UserType.TOOLFORGE_TOOL

    def get_relative_path(self, user: str) -> Path:
        return (
            # flake8: noqa
            Path(user[len(self.config.tools_project_prefix) + 1 :])
            / "replica.my.cnf"
        )


class PawsUserFileBackend(ToolforgeUserFileBackend):
    USER_TYPE = UserType.PAWS_USER

    def handles_user_type(self, user_type: UserType) -> bool:
        return user_type == UserType.PAWS_USER

    def get_relative_path(self, user: str) -> Path:
        return Path(user) / ".my.cnf"
