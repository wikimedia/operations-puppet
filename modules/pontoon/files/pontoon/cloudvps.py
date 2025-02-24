#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import fnmatch
import logging
import os
from typing import Any, Dict, List, Optional, Set
from dataclasses import dataclass


from ruamel.yaml import YAML

from . import Pontoon
from .credentials import Credentials
from .nova import HOST_DOMAIN, NovaClient, NovaAuth
from .util import user_confirmation, wait_hosts_access

log = logging.getLogger()


@dataclass
class Specs:
    """Cloud server specifications."""

    image: Any
    flavor: Any


@dataclass
class CloudHost:
    """Represents a cloud host with relevant properties."""

    fqdn: str
    image: str
    flavor: str


class CloudVPS(object):
    """Control a Pontoon stack via Cloud VPS."""

    def __init__(self, pontoon: Pontoon, creds: Credentials):
        self.pontoon = pontoon
        self.nova = NovaClient(NovaAuth(creds.id, creds.secret))
        self.creds = creds
        self.yaml = YAML()
        self._specmap = None

    @property
    def specmap(self) -> Dict[str, Any]:
        if self._specmap is not None:
            return self._specmap
        self._specmap = self._load_specmap()
        return self._specmap

    @property
    def project_id(self) -> Optional[str]:
        return self.nova.project_id

    def _load_specmap(self) -> Dict[str, Any]:
        specmap = {}

        specfile = os.path.join(self.pontoon.base_path, "specmap.yaml")
        with open(specfile, encoding="utf-8") as f:
            specmap = self.yaml.load(f)

        stack_specfile = os.path.join(self.pontoon.stack_path, "specmap.yaml")
        if os.path.exists(stack_specfile):
            with open(stack_specfile, encoding="utf-8") as f:
                stack_specmap = self.yaml.load(f)
                specmap.update(stack_specmap)

        return specmap

    def specs_for_role(self, role: str) -> Specs:
        """Get Specs for role.
        The 'default' role will be used if the role
        doesn't have an explicit Spec.

        Args:
            role (str): The role name

        Returns:
            Specs: The specs for this role
        """
        role_specs = self.specmap["__default"]
        role_specs.update(self.specmap.get(role, {}))

        return Specs(
            image=self.nova.name_image(role_specs["image"]),
            flavor=self.nova.name_flavor(role_specs["flavor"]),
        )

    @property
    def fqdns(self) -> List[str]:
        return self.nova.fqdns()

    def fqdn(self, host: str) -> str:
        return f"{host}.{self.project}.{HOST_DOMAIN}"

    @property
    def project(self):
        return self.nova.project_id

    @property
    def openstack_config(self) -> Dict:
        """Return configuration for openstack CLI tools."""
        stack = self.pontoon.name
        auth_cfg = {
            "auth_url": self.nova.auth.auth_url,
            "application_credential_secret": self.creds.secret,
            "application_credential_id": self.creds.id,
        }
        cfg = {
            "clouds": {
                stack: {
                    "interface": "public",
                    "identity_api_version": 3,
                    "auth_type": "v3applicationcredential",
                    "auth": auth_cfg,
                }
            }
        }
        return cfg

    def list_hosts(self) -> List[CloudHost]:
        """List details about hosts (FQDNs) for the current project.

        Returns:
            List[CloudHost]: A list of CloudHost objects.
        """
        hosts = []

        for host in self.nova.servers():
            cloud_host = CloudHost(
                fqdn=self.nova.server_fqdn(host),
                image=self.nova.server_image(host).name,
                flavor=self.nova.server_flavor(host).name,
            )
            hosts.append(cloud_host)

        return hosts

    def create_hosts(
        self, dry_run=False, no_block=False, hosts: Optional[Set[str]] = None
    ) -> bool:
        cloud_hosts = {h for h in self.fqdns}
        if hosts is None:
            stack_hosts = {h for h in self.pontoon.host_map().keys()}
        else:
            stack_hosts = set(hosts)

        to_add = []
        candidates = stack_hosts - cloud_hosts
        if not candidates:
            log.info("All hosts already created")
            return False

        for host in candidates:
            role = self.pontoon.role_for_host(host)
            if role:
                specs = self.specs_for_role(role)
                to_add.append((host, specs.image, specs.flavor))

        if dry_run:
            print(f"Will add {to_add!r}")
        else:
            for server in to_add:
                log.info(f"Creating {server}")
                self.nova.create_server(*server)

        if no_block:
            return True

        return wait_hosts_access(set([x[0] for x in to_add]))

    def destroy_hosts(self, pattern: str, dry_run=True) -> bool:
        cloud_servers = self.nova.servers()
        to_delete = [x for x in cloud_servers if fnmatch.fnmatch(x.name, pattern)]
        if len(to_delete) == 0:
            print("No hosts to delete")
            return True

        print(f"Hosts to remove that match {pattern}:")
        for i in to_delete:
            print(f"  {i.name}")

        answer = user_confirmation(
            f"About to delete {len(to_delete)} host(s). Input the number to confirm: ",
            int,
        )

        if answer != len(to_delete):
            print("Not doing anything")
            return False

        for server in to_delete:
            self.nova.delete_server(server)

        return True

    def reboot_hosts(self, pattern: str, reboot_type: str, no_block=False) -> bool:
        cloud_servers = self.nova.servers()
        to_reboot = [x for x in cloud_servers if fnmatch.fnmatch(x.name, pattern)]
        if len(to_reboot) == 0:
            print("No hosts to reboot")
            return True

        print(f"Hosts to reboot that match {pattern}:")
        for i in to_reboot:
            print(f"  {i.name}")

        answer = user_confirmation(
            f"About to reboot {len(to_reboot)} host(s). Input the number to confirm: ",
            int,
        )

        if answer != len(to_reboot):
            print("Not doing anything")
            return False

        for server in to_reboot:
            self.nova.reboot_server(server, reboot_type)

        if no_block:
            return True

        return wait_hosts_access(
            set([f"{x.name}.{self.nova.project_id}.{HOST_DOMAIN}" for x in to_reboot])
        )
