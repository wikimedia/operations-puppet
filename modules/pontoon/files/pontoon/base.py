#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import logging
import shutil
import os
from dataclasses import asdict, dataclass, fields
from pathlib import Path
from typing import Any, Dict, List, Optional

from ruamel.yaml import YAML

log = logging.getLogger()


# a module-level attribute for sys_config_path would read nicer.
# Unfortunately, reading 'os.environ' becomes problematic in tests where the
# module might have been already initialized. Doing it this way effectively
# means a lazy evaluation and thus setting XDG_CONFIG_HOME works as expected
# (e.g. in tests/ctl_test.py)
def SYS_CONFIG_PATH() -> Path:
    """Where to store Pontoon configuration not specific to a stack."""
    p = Path(os.environ.get("XDG_CONFIG_HOME", "~/.config"))
    return p.joinpath("pontoon").expanduser()


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
        self.stack_config_path = os.path.join(self.stack_path, "config.yaml")
        self.yaml = YAML()
        with open(self.rolemap_path) as f:
            self.rolemap = self.yaml.load(f)
        self.config = self._load_config()

    @property
    def available_stacks(self) -> List[str]:
        base = Path(self.base_path)
        return [
            d.name
            for d in base.iterdir()
            if d.is_dir() and (d / "rolemap.yaml").exists()
        ]

    @property
    def available_roles(self) -> List[str]:
        return list(self.rolemap.keys())

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
        os.makedirs(os.path.join(stack_path, "hiera"), exist_ok=True)

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
                    # XXX detect duplicates early?
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

    def _load_config(self) -> "StackConfig":
        if not os.path.exists(self.stack_config_path):
            with open(self.stack_config_path, "w") as f:
                f.write("# SPDX-License-Identifier: Apache-2.0\n{}\n")

        with open(self.stack_config_path, "r") as file:
            data = self.yaml.load(file)
        return StackConfig.from_dict(data)

    def set_config_value(self, key: str, value: Any):
        if hasattr(self.config, key):
            setattr(self.config, key, value)
        else:
            raise KeyError(f"Invalid configuration key: {key}")

    def get_config_value(self, key: str) -> Any:
        if hasattr(self.config, key):
            return getattr(self.config, key)
        else:
            raise KeyError(f"Invalid configuration key: {key}")

    def save(self):
        """Write the stack to disk."""
        with open(self.rolemap_path, "w") as f:
            self.yaml.dump(self.rolemap, f)

        with open(self.stack_config_path, "w") as f:
            self.yaml.dump(asdict(self.config), f)

    def delete(self):
        """Remove the stack from disk."""
        shutil.rmtree(self.stack_path)


@dataclass
class StackConfig:
    host_prefix: str = ""

    @classmethod
    def from_dict(cls, data: dict):
        """Create StackConfig from a dictionary, ensuring all fields are populated."""
        field_names = {f.name for f in fields(cls)}
        filtered_data = {k: v for k, v in data.items() if k in field_names}
        return cls(**filtered_data)
