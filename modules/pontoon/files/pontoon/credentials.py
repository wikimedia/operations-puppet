#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import os
import stat

from ruamel.yaml import YAML


# XXX rework to use dataclasses like base.StackConfig
class Credentials(object):
    def __init__(self, config_path: str):
        self.config_path = config_path

        if not os.path.exists(self.config_path):
            raise CredentialsMissing

        if os.stat(self.config_path).st_mode & stat.S_IROTH:
            raise ValueError(f"wrong permissions: chmod a=,u=r {self.config_path}")

        with open(self.config_path) as f:
            loaded = YAML().load(f)

        try:
            self.creds = loaded["credentials"]["default"]
            self.id = self.creds["id"]
            self.secret = self.creds["secret"]
        except KeyError:
            raise CredentialsMissing

    @staticmethod
    def write(path: str, id: str, secret: str):
        with open(path, "w") as f:
            creds = {"credentials": {"default": {"id": id, "secret": secret}}}
            YAML().dump(creds, f)
        os.chmod(path, 0o600)


class CredentialsMissing(Exception):
    pass


def load_credentials(config_path: str) -> Credentials:
    config_dir = os.path.dirname(config_path)
    if not os.path.exists(config_dir):
        os.makedirs(config_dir)

    return Credentials(config_path)
