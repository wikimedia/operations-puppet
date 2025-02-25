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
    """Cloud server specifications for new VMs. Roles are mapped to specs in specmap.yaml."""

    image: str
    flavor: str
    hostname: str  # used to generate the hostname


@dataclass
class CloudHost:
    """Represents an existing cloud host."""

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
        The '__default' role will be used if the role
        doesn't have an explicit Spec.

        Args:
            role (str): The role name

        Returns:
            Specs: The specs for this role
        """
        role_specs = self.specmap["__default"].copy()
        role_specs.update(self.specmap.get(role, {}))

        if role_specs.get("hostname") is None:
            role_specs["hostname"] = role.replace(":", "_")

        return Specs(
            image=role_specs["image"],
            flavor=role_specs["flavor"],
            hostname=role_specs["hostname"],
        )

    @property
    def fqdns(self) -> List[str]:
        """Return a list of FQDNs for the current project."""
        return self.nova.fqdns()

    def fqdn(self, host: str) -> str:
        """Return the FQDN for a host in the current project."""
        return f"{host}.{self.project}.{HOST_DOMAIN}"

    @property
    def project(self):
        """Return the current project."""
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
        self,
        block=True,
        hosts: Optional[Set[str]] = None,
        role: Optional[str] = None,
    ) -> bool:
        """Create hosts for roles in the Pontoon stack."""
        stack_hosts = {h for h in self.pontoon.host_map().keys()}
        if hosts is not None:
            hosts = set(hosts)
        elif role is not None:
            stack_hosts = set(self.pontoon.hosts_for_role(role))

        cloud_hosts = {h for h in self.fqdns}
        candidates = stack_hosts - cloud_hosts
        if not candidates:
            log.info("All hosts already created")
            return False

        to_add = []
        for host in candidates:
            host_role = self.pontoon.role_for_host(host)
            if not host_role:
                log.error(f"Role not found for host {host}")
                continue
            specs = self.specs_for_role(host_role)
            image = self.nova.name_image(specs.image)
            flavor = self.nova.name_flavor(specs.flavor)
            to_add.append((host, image, flavor))

        for server in to_add:
            log.info(f"Creating {server}")
            self.nova.create_server(*server)

        if not block:
            return True

        return wait_hosts_access(set([x[0] for x in to_add]))

    def destroy_hosts(self, pattern: str, role: Optional[str] = None) -> bool:
        def _should_delete(server):
            if role is not None:
                return self.fqdn(server.name) in self.pontoon.hosts_for_role(role)
            else:
                return (
                    fnmatch.fnmatch(server.name, pattern)
                    # match pattern against fqdn too for convenience (e.g. copy/paste fqdn)
                    or fnmatch.fnmatch(self.fqdn(server.name), pattern)
                )

        cloud_servers = self.nova.servers()
        to_delete = [x for x in cloud_servers if _should_delete(x)]
        if len(to_delete) == 0:
            log.info("No hosts to delete")
            return True

        log.info(f"Hosts to remove matching {role or pattern}:")
        for i in to_delete:
            print(f"  {i.name}")

        answer = user_confirmation(
            f"About to delete {len(to_delete)} host(s). Input the number to confirm: ",
            int,
        )

        if answer != len(to_delete):
            log.info("Not doing anything")
            return False

        for server in to_delete:
            self.nova.delete_server(server)

        return True

    def reboot_hosts(
        self, pattern: str, reboot_type: str, block=True, role: Optional[str] = None
    ) -> bool:
        def _should_reboot(server):
            if role is not None:
                return self.fqdn(server.name) in self.pontoon.hosts_for_role(role)
            else:
                return (
                    fnmatch.fnmatch(server.name, pattern)
                    # match pattern against fqdn too for convenience (e.g. copy/paste fqdn)
                    or fnmatch.fnmatch(self.fqdn(server.name), pattern)
                )

        cloud_servers = self.nova.servers()
        to_reboot = [x for x in cloud_servers if _should_reboot(x)]
        if len(to_reboot) == 0:
            log.info("No hosts to reboot")
            return True

        log.info(f"Hosts to reboot matching {role or pattern}:")
        for i in to_reboot:
            print(f"  {i.name}")

        answer = user_confirmation(
            f"About to reboot {len(to_reboot)} host(s). Input the number to confirm: ",
            int,
        )

        if answer != len(to_reboot):
            log.info("Not doing anything")
            return False

        for server in to_reboot:
            self.nova.reboot_server(server, reboot_type)

        if not block:
            return True

        return wait_hosts_access(set([self.fqdn(x.name) for x in to_reboot]))
