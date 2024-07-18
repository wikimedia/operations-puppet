#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

import http
import json
from dataclasses import dataclass
from pathlib import Path
from typing import cast

import requests
from flask import current_app
from replica_cnf_api_service.backends.common import (
    DRY_RUN_PASSWORD,
    DRY_RUN_USERNAME,
    Backend,
    Config,
    ReplicaCnf,
    Skip,
    UserType,
    run_script,
)
from toolforge_weld.api_client import ToolforgeClient
from toolforge_weld.kubernetes_config import Kubeconfig

USER_AGENT = "replica_cnf_api"


class EnvvarsBackedError(Exception):
    pass


@dataclass
class EnvvarsConfig(Config):
    # this is the templated path to a kubeconfig file
    # the format is python's str.format function
    # the parameters used are `user` (you can not use it if you prefer)
    # ex: "/data/project/{user}/.kube/config"
    kubeconfig_path_template: str
    toolforge_api_endpoint: str
    scripts_path: Path
    use_sudo: bool


class ToolforgeToolEnvvarsBackend(Backend):
    USER_TYPE = UserType.TOOLFORGE_TOOL
    VAR_PREFIX = "TOOL_"
    USER_ENVVARS = [f"{VAR_PREFIX}TOOLSDB_USER", f"{VAR_PREFIX}REPLICA_USER"]
    PASSWORD_ENVVARS = [f"{VAR_PREFIX}TOOLSDB_PASSWORD", f"{VAR_PREFIX}REPLICA_PASSWORD"]

    def __init__(self, config: Config):
        self.config: EnvvarsConfig = cast(EnvvarsConfig, config)

    def _get_user_client(self, user_name: str) -> ToolforgeClient:
        user_without_prefix = user_name.split(".", 1)[-1]
        kubeconfig_data_run = run_script(
            script="load_user_kubeconfig.py",
            scripts_path=self.config.scripts_path,
            use_sudo=self.config.use_sudo,
            args=[user_without_prefix],
        )
        if kubeconfig_data_run.returncode != 0:
            raise RuntimeError(
                f"Unable to get kubeconfig for user '{user_name}':"
                f"\nout:{kubeconfig_data_run.stdout}"
                f"\nerr:{kubeconfig_data_run.stderr}"
            )
        kubeconfig_data = json.loads(kubeconfig_data_run.stdout.decode("utf-8"))
        kubeconfig = Kubeconfig(**kubeconfig_data)
        return ToolforgeClient(
            server=self.config.toolforge_api_endpoint,
            kubeconfig=kubeconfig,
            user_agent=USER_AGENT,
        )

    def handles_user_type(self, user_type: UserType) -> bool:
        return self.USER_TYPE == user_type

    def _create_envvar(self, name: str, value: str, client, toolname: str) -> None:
        try:
            client.get(url=f"/envvars/v1/tool/{toolname}/envvars/{name}")
            current_app.logger.debug("Skipping setting existing var %s", name)
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == http.HTTPStatus.NOT_FOUND:
                client.post(
                    url=f"/envvars/v1/tool/{toolname}/envvar",
                    json={"name": name, "value": value},
                )
            else:
                raise

    def save_replica_cnf(
        self, replica_cnf: ReplicaCnf, account_uid: int, dry_run: bool
    ) -> ReplicaCnf:
        cli = self._get_user_client(user_name=replica_cnf.user)
        if dry_run:
            return replica_cnf

        toolname = replica_cnf.user.split(".", 1)[-1]
        for var in self.USER_ENVVARS:
            self._create_envvar(name=var, value=replica_cnf.db_user, client=cli, toolname=toolname)

        for var in self.PASSWORD_ENVVARS:
            self._create_envvar(
                name=var, value=replica_cnf.db_password, client=cli, toolname=toolname
            )

        return replica_cnf

    def delete_replica_cnf(self, user: str, user_type: UserType, dry_run: bool) -> None:
        cli = self._get_user_client(user_name=user)
        toolname = user.split(".", 1)[-1]
        if dry_run:
            return

        for var in self.USER_ENVVARS + self.PASSWORD_ENVVARS:
            cli.delete(url=f"/envvars/v1/tool/{toolname}/envvars/{var}")

    def get_replica_cnf(self, user: str, user_type: UserType, dry_run: bool) -> ReplicaCnf:
        """Note that we don't store the mysql hash but the plain password."""
        if dry_run:  # return dummy username and password if dry_run is True
            return ReplicaCnf(
                user_type=self.USER_TYPE,
                user=user,
                db_user=DRY_RUN_USERNAME,
                db_password=DRY_RUN_PASSWORD,
            )

        cli = self._get_user_client(user_name=user)
        toolname = user.split(".", 1)[-1]

        # TODO: Once all the users have the auth on envvars, we should fail instead of skipping
        # TODO: We will want to change the return value if we ever have different user/pass for
        #       replicas and toolsdb
        try:
            db_user_response = cli.get(
                url=f"/envvars/v1/tool/{toolname}/envvars/{self.USER_ENVVARS[0]}"
            )
            db_password_response = cli.get(
                url=f"/envvars/v1/tool/{toolname}/envvars/{self.PASSWORD_ENVVARS[0]}"
            )
        except requests.exceptions.HTTPError as e:
            raise Skip(
                f"Skipping failed envvars backend, maybe the variable is not yet set? {e}",
                dest_path="OK",
            ) from e

        try:
            db_password = db_password_response["envvar"]["value"]
            db_user = db_user_response["envvar"]["value"]
        except Exception as error:
            raise EnvvarsBackedError(
                "Got error trying to parse response from server: "
                f"{error}\nResponse:\n{db_password_response}\n{db_user_response}\n"
            ) from error

        return ReplicaCnf(
            user_type=user_type,
            user=user,
            db_password=db_password,
            db_user=db_user,
        )
