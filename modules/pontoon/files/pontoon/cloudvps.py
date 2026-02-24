#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import logging
import os
from dataclasses import dataclass
from fnmatch import fnmatch
from typing import Any, Callable, Dict, List, Optional, TypeVar

from pontoon import Pontoon
from pontoon.credentials import Credentials
from pontoon.host import Filter, Host
from pontoon.nova import (
    HOST_DOMAIN,
    NOVA_DEFAULT_URL,
    NovaAuth,
    NovaClient,
    NovaSpecs,
    Server,
)
from ruamel.yaml import YAML

# Type variable for Host or CloudHost
H = TypeVar("H", bound=Host)

log = logging.getLogger()


@dataclass
class Specs:
    """Cloud server specifications for new VMs. Roles are mapped to specs in specmap.yaml."""

    image: str
    flavor: str
    hostname: str  # used to generate the hostname


@dataclass
class CloudHost(Host):
    """Represents an existing cloud host with cloud-specific properties.

    This enhances the base Host class with additional Cloud VPS specific
    attributes like image and flavor.
    """

    fqdn: str
    image: str
    flavor: str
    role: str = "unknown"  # Default to unknown if role not provided

    def __init__(self, fqdn: str, image: str, flavor: str, role: str = "unknown"):
        """Initialize a CloudHost instance.

        Args:
            fqdn: Fully qualified domain name
            image: OS image name
            flavor: VM flavor/size
            role: Puppet role of the host (defaults to "unknown")
        """
        super().__init__(fqdn, role)
        self.image = image
        self.flavor = flavor


class CloudVPS(object):
    """Control a Pontoon stack via Cloud VPS."""

    def __init__(self, pontoon: Pontoon, creds: Credentials):
        self.pontoon = pontoon
        self.nova = NovaClient(NovaAuth.create(creds.id, creds.secret))
        self.creds = creds
        self.yaml = YAML()
        self._specmap: Optional[Dict[str, Any]] = None

    @property
    def specmap(self) -> Dict[str, Any]:
        if self._specmap is not None:
            return self._specmap
        self._specmap = self._load_specmap()
        return self._specmap

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
    def all_hosts_filter(self) -> Callable[[Host], bool]:
        """Return a filter function to identify hosts that exist in the cloud.

        To be used with Filter.apply to filter this project's hosts.

        Returns:
            A callable that returns True if a host exists in the cloud
        """
        # Create a set for faster lookups
        cloud_fqdns = set(self.nova.fqdns())
        return lambda host: host.fqdn in cloud_fqdns

    @staticmethod
    def by_image(image: Optional[str]) -> Callable[[H], bool]:
        """Filter hosts by image pattern.

        This only works on CloudHost objects. For regular Host objects,
        this will always return False.

        Args:
            image: Image name or pattern to match

        Returns:
            A callable filter function
        """
        if image is None:
            return lambda _: False

        def match(host):
            if not hasattr(host, "image"):
                return False
            return fnmatch(host.image, image)

        return match

    @staticmethod
    def by_flavor(flavor: Optional[str]) -> Callable[[H], bool]:
        """Filter hosts by flavor pattern.

        This only works on CloudHost objects. For regular Host objects,
        this will always return False.

        Args:
            flavor: Flavor name or pattern to match

        Returns:
            A callable filter function
        """
        if flavor is None:
            return lambda _: False

        def match(host):
            if not hasattr(host, "flavor"):
                return False
            return fnmatch(host.flavor, flavor)

        return match

    @property
    def project(self) -> Optional[str]:
        """Return the current project."""
        return self.nova.project

    @property
    def openstack_config(self) -> Dict:
        """Return configuration for openstack CLI tools."""
        stack = self.pontoon.name
        auth_cfg = {
            "auth_url": NOVA_DEFAULT_URL,
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
            List[CloudHost]: A list of CloudHost objects with role information
                from the stack when available.
        """
        # Get a mapping of FQDNs to roles from the stack
        stack_fqdn_to_role = self.pontoon.host_map()

        res: List[CloudHost] = []

        for server in self.nova.servers():
            fqdn = self.nova.server_fqdn(server)
            role = stack_fqdn_to_role.get(fqdn, "unknown")

            cloud_host = CloudHost(
                fqdn=fqdn,
                image=self.nova.server_image(server).name,
                flavor=self.nova.server_flavor(server).name,
                role=role,
            )
            res.append(cloud_host)

        return res

    def create_hosts(
        self,
        hosts: Filter,
    ) -> bool:
        """Create hosts in the Pontoon stack."""
        to_add: List[NovaSpecs] = []
        for host in hosts:
            hostname, _ = host.fqdn.split(".", 1)
            specs = self.specs_for_role(host.role)
            image = self.nova.name_image(specs.image)
            flavor = self.nova.name_flavor(specs.flavor)
            to_add.append(NovaSpecs(hostname, image, flavor))

        for spec in to_add:
            log.info(f"Creating {spec}")
            self.nova.create_server(spec)

        return True

    def destroy_host(self, host: Host) -> bool:
        server = self._server_for_host(host)
        self.nova.delete_server(server)
        return True

    def reboot_host(self, host: Host, reboot_type: str) -> bool:
        server = self._server_for_host(host)
        self.nova.reboot_server(server, reboot_type)
        return True

    def _server_for_host(self, host: Host) -> Server:
        # XXX this should be smarter, e.g. cache known hosts -> server mappings
        for s in self.nova.servers():
            if self.nova.server_fqdn(s) == host.fqdn:
                return s
        raise ValueError(f"Cloud server not found for {host}")
