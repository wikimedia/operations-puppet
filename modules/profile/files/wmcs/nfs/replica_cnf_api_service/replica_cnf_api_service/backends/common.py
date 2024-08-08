#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

import configparser
import io
import os
import subprocess
from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum
from hashlib import sha1
from pathlib import Path

DRY_RUN_USERNAME = "dry.run.username"
DRY_RUN_PASSWORD = "dry.run.password"


class BackendError(Exception):
    """Generic backend exception, parent of all others."""

    pass


class Skip(BackendError):
    """Indicates that the current action was skipped."""

    def __init__(self, message: str, dest_path: Path):
        super().__init__(message)
        # TODO: this makes no sense for envvars though, maybe remove eventually
        self.dest_path = dest_path


class UserType(Enum):
    PAWS_USER = "paws"
    TOOLFORGE_USER = "user"
    TOOLFORGE_TOOL = "tool"


@dataclass
class Config:
    @classmethod
    def from_yaml(cls, **params):
        instance_params = {}
        for param, param_cls in cls.__init__.__annotations__.items():
            if param == "return":
                continue

            if isinstance(param_cls, str):
                param_cls = eval(param_cls)

            if "path" in param and param_cls == Path:
                param_value = param_cls(os.path.expanduser(os.path.expandvars(str(params[param]))))
            else:
                param_value = param_cls(params[param])

            instance_params[param] = param_value

        return cls(**instance_params)


@dataclass
class ReplicaCnf:
    user_type: UserType
    # full username including the project prefix, ex. toolsbeta.test
    user: str
    db_user: str
    db_password: str

    def to_mysql_conf_str(self) -> str:
        replica_config = configparser.ConfigParser()
        replica_config["client"] = {
            "user": self.db_user,
            "password": self.db_password,
        }

        # Because ConfigParser can only write to a file
        # and not just return the value as a string directly
        replica_buffer = io.StringIO()
        replica_config.write(replica_buffer)
        return replica_buffer.getvalue()


class Backend(ABC):
    @abstractmethod
    def __init__(self, config: Config):
        pass

    @abstractmethod
    def save_replica_cnf(
        self, replica_cnf: ReplicaCnf, account_uid: int, dry_run: bool
    ) -> ReplicaCnf:
        pass

    @abstractmethod
    def delete_replica_cnf(self, user: str, user_type: UserType, dry_run: bool) -> None:
        pass

    @abstractmethod
    def get_replica_cnf(self, user: str, user_type: UserType, dry_run: bool) -> ReplicaCnf:
        pass

    @abstractmethod
    def handles_user_type(self, user_type: UserType) -> bool:
        pass


def mysql_hash(password):
    """
    Hash a password to mimic MySQL's PASSWORD() function
    """
    return "*" + sha1(sha1(password.encode("utf-8")).digest()).hexdigest()


def get_command_array(script: str, scripts_path: Path, use_sudo: bool):
    full_path = str(scripts_path / script)
    if use_sudo:
        return ["sudo", "--preserve-env=CONF_FILE", full_path]
    else:
        return [full_path]


def run_script(
    script: str,
    scripts_path: Path,
    use_sudo: bool,
    args: list[str],
) -> subprocess.CompletedProcess[bytes]:
    env = {
        "PATH": os.getenv("PATH", ""),
    }
    # In the VMs we can't set it at all because sudo prevents us,
    # so only setting it if it's actually passed (testing)
    if os.getenv("CONF_FILE", "") != "":
        env["CONF_FILE"] = os.getenv("CONF_FILE", "")

    return subprocess.run(
        get_command_array(
            script=script,
            scripts_path=scripts_path,
            use_sudo=use_sudo,
        )
        + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        env=env,
    )
