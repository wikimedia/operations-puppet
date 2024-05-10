# SPDX-License-Identifier: Apache-2.0

import argparse
import logging
import os
import shlex
import subprocess
from typing import Dict, List, Optional, Type

from ruamel.yaml import YAML

log = logging.getLogger()

SSH_CONNECT_TIMEOUT_SECONDS = 6


class Pontoon(object):
    """This class represents a Pontoon stack.

    A stack is defined by its name and a filesystem path where its configuration can be found.
    """

    def __init__(self, name: str, base_path: str = "."):
        """Load an existing stack.

        Args:
            name (str): The stack name
            base_path (str, optional): Path used to locate the stack configuration.
                Must contain a directory named after the stack. Defaults to ".".
        """
        self.name = name
        self.base_path = base_path
        self.rolemap_path = os.path.join(self.stack_path, "rolemap.yaml")
        self.yaml = YAML()
        with open(self.rolemap_path) as f:
            self.rolemap = self.yaml.load(f)

    @property
    def stack_path(self) -> str:
        return os.path.join(self.base_path, self.name)

    @property
    def server_fqdn(self) -> Optional[str]:
        """
        Returns:
            Optional[str]: This stack's Puppet server FQDN
        """
        try:
            return self.hosts_for_role("puppetserver::pontoon")[0]
        except (ValueError, IndexError):
            return None

    @staticmethod
    def new(name: str, base_path: str = ".") -> "Pontoon":
        """Initialize a new Pontoon stack.

        Args:
            name (str): The stack name
            base_path (str, optional): Path to write the stack's configuration. Defaults to ".".

        Returns:
            Pontoon: The newly created stack
        """
        stack_path = os.path.join(base_path, name)
        os.makedirs(stack_path, exist_ok=True)
        rolemap_path = os.path.join(stack_path, "rolemap.yaml")
        if not os.path.exists(rolemap_path):
            with open(rolemap_path, "w+") as f:
                f.write("# SPDX-License-Identifier: Apache-2.0\n{}\n")
        os.makedirs(os.path.join(stack_path, 'hiera'), exist_ok=True)

        return Pontoon(name, base_path)

    def host_map(self) -> Dict[str, str]:
        """
        Returns:
            Dict[str, str]: Host (FQDN) to role map
        """
        res = {}
        for role, hosts in self.rolemap.items():
            for h in hosts:
                if h in res:
                    log.warning("Duplicate host %s", h)
                    continue
                res[h] = role
        return res

    def role_variables(self) -> Dict[str, str]:
        """The stack's variables, used for example by Pontoon ENC to generate Hiera values.

        Returns:
            Dict[str, str]: Variables for all stack roles
        """
        res = {}
        for role, hosts in self.rolemap.items():
            res["__hosts_for_role_%s" % role.replace(":", "_")] = hosts
            res["__master_for_role_%s" % role.replace(":", "_")] = hosts[0]
        return res

    def hosts_for_role(self, role: str) -> List[str]:
        """
        Args:
            role (str): The role's name

        Raises:
            ValueError: On role not found in stack

        Returns:
            List[str]: The hosts (FQDN) mapped to the given role
        """
        if role not in self.rolemap:
            raise ValueError("Role %s not found" % role)
        return self.rolemap.get(role)

    def role_for_host(self, fqdn: str) -> Optional[str]:
        """

        Args:
            fqdn (str): The host to search role for

        Returns:
            Optional[str]: The host's role, or None if host not found.
        """
        return self.host_map().get(fqdn, None)

    def add_host_to_role(self, fqdn: str, role: str):
        """Add an host (FQDN) to a role.

        Args:
            fqdn (str): The host to add
            role (str): The role to add to
        """
        if role not in self.rolemap:
            self.rolemap[role] = [fqdn]
        hosts = self.rolemap.get(role, [])
        if fqdn not in hosts:
            hosts.append(fqdn)

    def save(self):
        """Write the stack configuration to disk."""
        with open(self.rolemap_path, "w") as f:
            self.yaml.dump(self.rolemap, f)

    def ssh_bash(self, fqdn, cmd, *args, **kwargs) -> subprocess.CompletedProcess[str]:
        ssh_cmd = [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            f"ConnectTimeout={SSH_CONNECT_TIMEOUT_SECONDS}",
        ]
        return subprocess.run(
            ssh_cmd + [fqdn, "bash", "-c", shlex.quote(cmd)], *args, **kwargs
        )
