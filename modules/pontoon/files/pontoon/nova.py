#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
from dataclasses import dataclass
from typing import Any, List, Optional, TypeVar, Generic

import importlib.metadata
from keystoneauth1 import session as keystone_session
from keystoneauth1.identity.v3 import ApplicationCredential
from novaclient import client as nova_client
from novaclient.v2.flavors import Flavor
from novaclient.v2.images import Image
from novaclient.v2.servers import Server

# Configuration constants
NOVA_DEFAULT_URL = "https://openstack.eqiad1.wikimediacloud.org:25000/v3"
HORIZON_URL = "https://horizon.wikimedia.org"
HOST_DOMAIN = "eqiad1.wikimedia.cloud"
NIC_NET_ID = "7425e328-560c-4f00-8e99-706f3fb90bb4"  # VLAN/legacy

# Try to get the app version
try:
    APP_VERSION = importlib.metadata.version("pontoon")
except importlib.metadata.PackageNotFoundError:
    APP_VERSION = "unknown"

APP_NAME = "pontoonctl"


@dataclass
class NovaSpecs:
    """Holds information for Nova to create a new Server"""

    hostname: str
    image: Image
    flavor: Flavor


class ImageDeleted(Image):
    """Represents a deleted image"""

    def __init__(self, name: str):
        self.name = name


# Generic cache type for better type hints
T = TypeVar("T")


class Cache(Generic[T]):
    """Generic cache to store and retrieve items by ID or name"""

    def __init__(self, fetcher_func):
        self._by_id = {}
        self._by_name = {}
        self._fetcher = fetcher_func
        self._initialized = False

    def get_by_id(self, item_id: str) -> T:
        """Get an item by its ID"""
        if not self._by_id:
            self._initialize()

        if item_id not in self._by_id:
            item = self._fetcher(item_id)
            self._by_id[item_id] = item
            self._by_name[item.name] = item

        return self._by_id[item_id]

    def get_by_name(self, name: str) -> T:
        """Get an item by its name"""
        if not self._by_name:
            self._initialize()

        return self._by_name[name]

    def _initialize(self):
        """Initialize the cache with items from the fetcher"""
        items = self._fetcher()
        self._by_id = {item.id: item for item in items}
        self._by_name = {item.name: item for item in items}
        self._initialized = True


class NovaAuth:
    """Creates an authentication object for Nova API"""

    @staticmethod
    def create(id: str, secret: str) -> ApplicationCredential:
        """Create an auth object for Nova API"""
        return ApplicationCredential(
            auth_url=NOVA_DEFAULT_URL,
            application_credential_id=id,
            application_credential_secret=secret,
            user_domain_id="default",
        )


class NovaSession:
    """Manages the Nova API session"""

    def __init__(self, auth: ApplicationCredential):
        self.auth = auth
        self._session = None
        self._project_id = None

    @property
    def session(self) -> keystone_session.Session:
        """Get the Keystone session"""
        if self._session is None:
            self._session = keystone_session.Session(
                auth=self.auth, app_name=APP_NAME, app_version=APP_VERSION
            )
        return self._session

    @property
    def project_id(self) -> Optional[str]:
        """Get the OpenStack project ID"""
        if self._project_id is None:
            self._project_id = self.session.get_project_id()
        return self._project_id


class NovaClient:
    """A wrapper for Nova client, with caching."""

    def __init__(self, auth: ApplicationCredential):
        self.session = NovaSession(auth)
        self._client = None

        # Initialize caches for flavors and images
        self.flavors = Cache[Flavor](self._get_flavors)
        self.images = Cache[Image](self._get_images)

    @property
    def client(self) -> Any:
        """Get the Nova client instance"""
        if self._client is None:
            self._client = nova_client.Client("2", session=self.session.session)
        return self._client

    @property
    def project_id(self) -> Optional[str]:
        """Get the OpenStack project ID"""
        return self.session.project_id

    def _get_flavors(self) -> List[Flavor]:
        """Fetch all flavors from Nova"""
        return self.client.flavors.list()

    def _get_images(self) -> List[Image]:
        """Fetch all images from Nova"""
        return self.client.glance.list()

    def servers(self) -> List[Server]:
        """Get all servers in the project"""
        return self.client.servers.list()

    def fqdns(self) -> List[str]:
        """Get FQDNs for all servers"""
        return [self.server_fqdn(h) for h in self.servers()]

    def server_fqdn(self, server: Server) -> str:
        """Create a FQDN for a server"""
        return f"{server.name}.{self.project_id}.{HOST_DOMAIN}"

    def delete_server(self, server: Server) -> Any:
        """Delete a server"""
        return self.client.servers.delete(server)

    def reboot_server(self, server: Server, reboot_type: str) -> Any:
        """Reboot a server"""
        return self.client.servers.reboot(server, reboot_type)

    def create_server(self, specs: NovaSpecs) -> Any:
        """Create a new server"""
        return self.client.servers.create(
            specs.hostname,
            specs.image,
            specs.flavor,
            nics=[{"net-id": NIC_NET_ID}],
        )

    def server_flavor(self, server: Server) -> Flavor:
        """Get the flavor of a server"""
        return self.flavors.get_by_id(server.flavor["id"])

    def name_flavor(self, name: str) -> Flavor:
        """Get a flavor by name"""
        return self.flavors.get_by_name(name)

    def server_image(self, server: Server) -> Image:
        """Get the image of a server"""
        image_id = server.image["id"]
        image = self.images.get_by_id(image_id)
        return image if image else ImageDeleted("image-not-found")

    def name_image(self, name: str) -> Image:
        """Get an image by name, with fallback to prefix matching"""
        image = self.images.get_by_name(name)
        if image:
            return image

        # Fallback to name image prefix
        all_names = sorted(self.images._by_name.keys(), reverse=True)
        for candidate in all_names:
            if candidate.startswith(name):
                return self.images._by_name.get(
                    candidate, ImageDeleted("image-not-found")
                )

        return ImageDeleted("name-not-found")
