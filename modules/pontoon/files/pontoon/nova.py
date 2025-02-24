#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
from typing import List, Optional

import pkg_resources
from keystoneauth1 import session as keystone_session
from keystoneauth1.identity.v3 import ApplicationCredential
from novaclient import client as nova_client
from novaclient.v2.flavors import Flavor
from novaclient.v2.images import Image
from novaclient.v2.servers import Server

try:
    APP_VERSION = pkg_resources.get_distribution("pontoon").version
except pkg_resources.DistributionNotFound:
    APP_VERSION = "unknown"

NOVA_DEFAULT_URL = "https://openstack.eqiad1.wikimediacloud.org:25000/v3"
HORIZON_URL = "https://horizon.wikimedia.org"
HOST_DOMAIN = "eqiad1.wikimedia.cloud"
NIC_NET_ID = "7425e328-560c-4f00-8e99-706f3fb90bb4"  # lan-flat-cloudinstances2b
APP_NAME = "pontoonctl"


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
    def project_id(self) -> Optional[str]:
        if self._project_id is not None:
            return self._project_id
        self._project_id = self.session.get_project_id()
        return self._project_id

    def servers(self) -> List[Server]:
        return self.client.servers.list()

    def fqdns(self) -> List[str]:
        return [f"{self.server_fqdn(h)}" for h in self.servers()]

    def server_fqdn(self, server: Server) -> str:
        return f"{server.name}.{self.project_id}.{HOST_DOMAIN}"

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
