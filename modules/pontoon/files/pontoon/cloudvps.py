#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import fnmatch
import json
import logging
import os
import subprocess
import time
from collections import namedtuple
from typing import Any, Dict, List, Optional, Set, Tuple, Type

import pkg_resources
from keystoneauth1 import session as keystone_session
from keystoneauth1.identity.v3 import ApplicationCredential
from novaclient import client as nova_client
from novaclient.v2.flavors import Flavor
from novaclient.v2.images import Image
from novaclient.v2.servers import Server
from ruamel.yaml import YAML

from . import Enroller, Pontoon

HOSTS_ACCESS_TIMEOUT_MINUTES = 5
NOVA_DEFAULT_URL = "https://openstack.eqiad1.wikimediacloud.org:25000/v3"
HORIZON_URL = "https://horizon.wikimedia.org"
HOST_DOMAIN = "eqiad1.wikimedia.cloud"
NIC_NET_ID = "7425e328-560c-4f00-8e99-706f3fb90bb4"  # lan-flat-cloudinstances2b
APP_NAME = "pontoonctl"

try:
    APP_VERSION = pkg_resources.get_distribution("pontoon").version
except pkg_resources.DistributionNotFound:
    APP_VERSION = "unknown"

log = logging.getLogger()


class NovaClient(object):
    """A wrapper for Nova client, with caching."""

    def __init__(self, auth: ApplicationCredential):
        self.auth = auth
        self._client = None
        self._session = None
        self._project_id = None
        self._flavor_ids = {}
        self._flavor_names = {}
        self._image_ids = {}
        self._image_names = {}

    @property
    def client(self):
        if self._client is not None:
            return self._client
        self._client = nova_client.Client("2", session=self.session)
        return self._client

    @property
    def session(self) -> keystone_session.Session:
        if self._session is not None:
            return self._session
        self._session = keystone_session.Session(
            auth=self.auth, app_name=APP_NAME, app_version=APP_VERSION
        )
        return self._session

    @property
    def project_id(self) -> str:
        if self._project_id is not None:
            return self._project_id
        self._project_id = self.session.get_project_id()
        return self._project_id

    def servers(self) -> List[Any]:
        return self.client.servers.list()

    def fqdns(self) -> List[str]:
        return [f"{h.name}.{self.project_id}.{HOST_DOMAIN}" for h in self.servers()]

    def delete_server(self, server: Server):
        return self.client.servers.delete(server)

    def reboot_server(self, server: Server, reboot_type: str):
        return self.client.servers.reboot(server, reboot_type)

    def create_server(self, fqdn: str, image: str, flavor: str):
        return self.client.servers.create(
            fqdn.split(".")[0],
            image,
            flavor,
            nics=[{"net-id": NIC_NET_ID}],
        )

    def server_flavor(self, server: Server) -> Flavor:
        if not self._flavor_ids:
            self._flavor_ids = {f.id: f for f in self.client.flavors.list()}

        f = server.flavor["id"]
        if f not in self._flavor_ids:
            self._flavor_ids[f] = self.client.flavors.get(f)

        return self._flavor_ids[f]

    def name_flavor(self, name: str) -> str:
        if not self._flavor_names:
            self._flavor_names = {f.name: f for f in self.client.flavors.list()}

        if name not in self._flavor_names:
            self._flavor_names[name] = self.client.flavors.get(name)

        return self._flavor_names[name]

    def server_image(self, server: Server) -> Image:
        if not self._image_ids:
            self._image_ids = {i.id: i for i in self.client.glance.list()}

        i = server.image["id"]
        return self._image_ids.get(i, ImageDeleted("image-not-found"))

    def name_image(self, name):
        if not self._image_names:
            self._image_names = {i.name: i for i in self.client.glance.list()}

        res = self._image_names.get(name)
        if res is not None:
            return res

        # Fallback to name image prefix
        all_names = sorted(self._image_names, reverse=True)
        for candidate in all_names:
            if candidate.startswith(name):
                return self._image_names.get(candidate)

        return ImageDeleted("name-not-found")


class ImageDeleted(Image):
    def __init__(self, name: str):
        self.name = name


def NovaAuth(id: str, secret: str) -> ApplicationCredential:
    return ApplicationCredential(
        auth_url=NOVA_DEFAULT_URL,
        application_credential_id=id,
        application_credential_secret=secret,
        user_domain_id="default",
    )


"""Cloud server specifications."""
Specs = namedtuple("Specs", ["image", "flavor"])


class CloudVPS(object):
    """Control a Pontoon stack via Cloud VPS."""

    def __init__(self, pontoon: Pontoon, auth: ApplicationCredential):
        self.pontoon = pontoon
        self.nova = NovaClient(auth)
        self.yaml = YAML()
        self._specmap = None

    @property
    def specmap(self) -> Dict[str, Any]:
        if self._specmap is not None:
            return self._specmap
        self._specmap = self._load_specmap()
        return self._specmap

    @property
    def project_id(self) -> str:
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

    def list_hosts(self, all: bool = False) -> Tuple[List[str], List[List]]:
        """List details about hosts (FQDNs) for the current project

        Returns:
            List[str]: The detail's description
            List[List]: A list of host details
        """
        data = []
        description = ["Name", "Image", "Flavor"]
        stack_fqdns = self.pontoon.host_map().keys()
        stack_hosts = [x.split(".", 1)[0] for x in stack_fqdns]

        for host in self.nova.servers():
            if not all and host.name not in stack_hosts:
                continue

            data.append(
                [
                    host.name,
                    self.nova.server_image(host).name,
                    self.nova.server_flavor(host).name,
                ]
            )

        return description, data

    def specs_for_role(self, role: str) -> Specs:
        """Get Specs for role.
        The 'default' role will be used if the role
        doesn't have an explicit Spec.

        Args:
            role (str): The role name

        Returns:
            Specs: The specs for this role
        """
        conf_specs = self.specmap["default"]
        conf_specs.update(self.specmap.get(role, {}))

        specs = {}
        specs.update(
            {
                "image": self.nova.name_image(conf_specs["image"]),
                "flavor": self.nova.name_flavor(conf_specs["flavor"]),
            }
        )

        return Specs(**specs)

    def create_hosts(
        self, dry_run=False, no_block=False, hosts: Optional[Set[str]] = None
    ) -> bool:
        cloud_hosts = {h for h in self.nova.fqdns()}
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

        return self._wait_hosts_access(set([x[0] for x in to_add]))

    def _wait_hosts_access(self, hosts: Set[str]):
        def proc_for_host(host):
            return subprocess.Popen(
                [
                    "ssh",
                    "-o",
                    "UserKnownHostsFile=/dev/null",
                    "-o",
                    "StrictHostKeyChecking=no",
                    "-o",
                    "BatchMode=yes",
                    "-o",
                    "ConnectTimeout=6",
                    host,
                    "sudo id",
                ],
                # stdout=subprocess.DEVNULL,
                # stderr=subprocess.DEVNULL,
            )

        procs = {h: proc_for_host(h) for h in hosts}

        deadline = time.time() + 60 * HOSTS_ACCESS_TIMEOUT_MINUTES
        while time.time() < deadline:
            done = []
            for host, proc in procs.items():
                status = proc.poll()
                if status is None:
                    continue
                if status == 0:
                    done.append(host)
                else:
                    procs[host] = proc_for_host(host)
            for host in done:
                del procs[host]

            if len(procs) == 0:
                return True

            log.info(f"Waiting access for: {','.join(list(procs.keys()))}")
            time.sleep(15)

        log.warning(f"Hosts not accessible past deadline: {list(procs.keys())!r}")
        return False

    def _host_prefix(self, stack_name):
        if "-" not in stack_name:
            return stack_name

        # Pick a short(er) name as host prefix
        novowels = stack_name.translate({ord(i): None for i in "aeiouAEIOU"})
        return novowels

    def user_confirmation(self, prompt: str, prompt_type: Type) -> Optional[Any]:
        answer = None
        while answer is None:
            try:
                answer = prompt_type(input(prompt))
            except ValueError:
                answer = None
        return answer

    def destroy_hosts(self, pattern: str, dry_run=True) -> bool:
        cloud_servers = self.nova.servers()
        to_delete = [x for x in cloud_servers if fnmatch.fnmatch(x.name, pattern)]
        if len(to_delete) == 0:
            print("No hosts to delete")
            return True

        print(f"Hosts to remove that match {pattern}:")
        for i in to_delete:
            print(f"  {i.name}")

        answer = self.user_confirmation(
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

        answer = self.user_confirmation(
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

        return self._wait_hosts_access(set([x.name for x in to_reboot]))

    def new_stack(self, host_prefix):
        if host_prefix is None:
            host_prefix = self._host_prefix(self.pontoon.name)

        server = self.pontoon.server_fqdn
        if server is not None:
            log.error(f"{self.pontoon.name} already exists ({server} found in rolemap)")
            return False

        fqdn = f"{host_prefix}-puppet-01.{self.nova.project_id}.{HOST_DOMAIN}"
        if fqdn in self.nova.fqdns():
            log.error(
                f"The server {fqdn} exists in project {self.nova.project_id},"
                f"choose a different prefix."
            )
            return False

        self.pontoon.add_host_to_role(fqdn, "puppetserver::pontoon")
        self.pontoon.save()
        return True

    def bootstrap_stack(self, from_local_rev):
        server_fqdn = self.pontoon.server_fqdn
        if not server_fqdn:
            log.error(f"Server not found for {self.pontoon.name}, unable to bootstrap")
            return False

        self.create_hosts(hosts=set([server_fqdn]))
        log.info(f"Bootstrapping {server_fqdn} for stack {self.pontoon.name}")
        bootstrap_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "bootstrap.sh"
        )
        status = subprocess.call(
            [
                "scp",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                bootstrap_path,
                server_fqdn + ":",
            ]
        )
        if status != 0:
            log.error("Error copying bootstrap.sh")
            return False

        proc = self.pontoon.ssh_bash(
            server_fqdn,
            f"sudo ./bootstrap.sh --check {self.pontoon.name}",
        )

        if proc.returncode == 2:
            log.info("Bootstrap already completed.")
            return True

        # Users can provide their code/data in $HOME/bootstrap
        send_local_checkout = f"""
        cd $(git rev-parse --show-toplevel) && \
            git archive --format tgz {from_local_rev} | \
                ssh -o stricthostkeychecking=no {server_fqdn} \
                    'install -d bootstrap/puppet && tar zxf - -C bootstrap/puppet'
        """
        log.info(f"Sending local checkout of {from_local_rev} to {server_fqdn}")
        subprocess.call(["bash", "-c", send_local_checkout])

        log.info(f"Bootstrapping {server_fqdn}")
        proc = self.pontoon.ssh_bash(
            server_fqdn, f"sudo ./bootstrap.sh {self.pontoon.name}"
        )

        if proc.returncode != 0:
            log.error(f"Error running bootstrap.sh on {server_fqdn}")
            return False

        # XXX run-puppet-agent (which is now available)

        return True

    def enroll_hosts(self, role: Optional[str], force=False):
        candidates = self.pontoon.host_map().keys()

        if role is not None:
            try:
                candidates = self.pontoon.hosts_for_role(role)
            except ValueError:
                log.error(f"Role {role!r} not found")
                return False

        if force:
            enrolled_hosts = []
        else:
            # Perform already-enrolled detection
            log.info("Searching for hosts not yet enrolled")
            proc = self.pontoon.ssh_bash(
                self.pontoon.server_fqdn,
                "sudo puppetserver ca list --format json --all",
                capture_output=True,
                text=True,
            )
            try:
                ca_list = json.loads(proc.stdout)
            except json.decoder.JSONDecodeError:
                log.error(f"Unable to get list of enrolled hosts from {proc.stdout!r}")
                return False
            enrolled_hosts = [x["name"] for x in ca_list["signed"]]

        to_enroll = set(candidates) - set(enrolled_hosts)

        if not to_enroll:
            log.info("No hosts to enroll")
            return False

        # Abort if the hosts are not known yet to the server
        proc = self.pontoon.ssh_bash(
            self.pontoon.server_fqdn,
            "pontoon-enc --list-hosts",
            capture_output=True,
            text=True,
        )
        enrollable_hosts = proc.stdout.split("\n")
        missing_on_server = set(to_enroll) - set(enrollable_hosts)
        if missing_on_server:
            log.error(
                f"Hosts to enroll and not found on Pontoon server: {missing_on_server}"
            )
            log.error("You might need to push an updated rolemap.yaml")
            return False

        e = Enroller(self.pontoon)
        ok = True
        for host in to_enroll:
            if not e.enroll(host, force=force):
                ok = False
        return ok
