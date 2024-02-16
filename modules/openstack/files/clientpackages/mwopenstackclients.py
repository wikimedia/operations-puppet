# SPDX-License-Identifier: Apache-2.0
import json
import logging
import os
import requests
from tenacity import before_sleep_log, retry, stop_after_attempt, wait_random
import yaml

import glanceclient
from keystoneauth1.identity.v3 import Password as KeystonePassword
from keystoneauth1 import session as keystone_session
from keystoneclient.v3 import client as keystone_client
from novaclient import client as nova_client
from designateclient.v2 import client as designateclient
from cinderclient.v3 import client as cinderclient
from troveclient.v1 import client as troveclient
from neutronclient.v2_0 import client as neutronclient
import openstack.config

logger = logging.getLogger("mwopenstackclients.DnsManager")


class Clients(object):
    """Wrapper class for creating OpenStack clients."""

    def __init__(
        self,
        envfile="",
        username="",
        password="",
        url="",
        project="",
        region="",
        oscloud="",
    ):
        """
        Read config from one of:
         - clouds.yaml (config specified by oscloud)
         - envfile arg
         - username, password, url, project args
         - execution environment varaiables
           (i.e. OS_USERNAME, OS_PASSWORD, OS_AUTH_URL, OS_PROJECT_ID)

        :param envfile: A puppetized yaml file like /etc/observerenv.yaml
        :param username: OpenStack user
        :param password: OpenStack password
        :param url: OpenStack authentication URL
        :param project: Project to authenticate to
        """
        self.sessions = {}
        self.keystoneclients = {}
        self.novaclients = {}
        self.glanceclients = {}
        self.designateclients = {}
        self.cinderclients = {}
        self.troveclients = {}
        self.neutronclients = {}
        self.project = None
        self.system_scope = None
        self.observerclient = None
        self.observersess = None

        # Cache these relationships since we have to do an exhaustive search
        self.project_ids_for_names = {}

        if oscloud:
            cloud_config = openstack.config.OpenStackConfig().get_all_clouds()
            for cloud in cloud_config:
                if cloud.name == oscloud:
                    if "project_id" in cloud.auth:
                        self.project = cloud.auth["project_id"]
                    if "system_scope" in cloud.auth:
                        self.system_scope = cloud.auth["system_scope"]
                    self.url = cloud.auth["auth_url"]
                    self.username = cloud.auth["username"]
                    self.password = cloud.auth["password"]
                    self.region = cloud.region_name
                    break
            else:
                raise Exception("%s not found in clouds.yaml", oscloud)
        elif envfile:
            if username or password or url or project:
                raise Exception("envfile is incompatible with specific args")

            with open(envfile) as f:
                env = yaml.safe_load(f)
                self.username = env["OS_USERNAME"]
                self.password = env["OS_PASSWORD"]
                self.url = env["OS_AUTH_URL"]
                self.project = env["OS_PROJECT_ID"]
                self.region = env["OS_REGION_NAME"]
        else:
            if username:
                self.username = username
            else:
                self.username = os.environ.get("OS_USERNAME", None)

            if password:
                self.password = password
            else:
                self.password = os.environ.get("OS_PASSWORD", None)

            if region:
                self.region = region
            else:
                self.region = os.environ.get("OS_REGION_NAME", None)

            if url:
                self.url = url
            else:
                self.url = os.environ.get("OS_AUTH_URL", None)

            if project:
                self.project = project
            else:
                self.project = os.environ.get("OS_PROJECT_ID", None)

        if not self.username:
            raise Exception("No username (env OS_USERNAME) specified")
        if not self.password:
            raise Exception("No password (env OS_PASSWORD) specified")
        if not self.url:
            raise Exception("No url (env OS_AUTH_URL) specified")

    def session(self, project=None):
        # You can use None as a dictionary key -- I looked it up!
        if project not in self.sessions:
            if not project:
                if self.system_scope:
                    # Get a system-scoped token
                    auth = KeystonePassword(
                        auth_url=self.url,
                        username=self.username,
                        password=self.password,
                        user_domain_name="Default",
                        system_scope=self.system_scope,
                    )
                else:
                    # Get a domain-scoped token
                    auth = KeystonePassword(
                        auth_url=self.url,
                        username=self.username,
                        password=self.password,
                        user_domain_name="Default",
                        domain_id="default",
                    )
            else:
                if project != self.project:
                    # Check the domain of the project before proceeding.
                    # We rely on a least one auth project (self.project)
                    # to already know its domain.
                    projectobj = self.observerkeystoneclient().projects.get(project)
                    projectdomain = projectobj.domain_id
                else:
                    projectdomain = "default"

                auth = KeystonePassword(
                    auth_url=self.url,
                    username=self.username,
                    password=self.password,
                    user_domain_name="Default",
                    project_domain_id=projectdomain,
                    project_id=project,
                )

            self.sessions[project] = keystone_session.Session(auth=auth)
        return self.sessions[project]

    def observersession(self):
        # Get a keystone session specifically using the novaobserver
        # credentials
        if not self.observersess:
            cloud_config = openstack.config.OpenStackConfig().get_one_cloud(
                "novaobserver"
            )
            auth = KeystonePassword(
                auth_url=cloud_config.auth["auth_url"],
                username=cloud_config.auth["username"],
                password=cloud_config.auth["password"],
                user_domain_name="Default",
                project_id=cloud_config.auth["project_id"],
                project_domain_id=cloud_config.auth["project_id"],
            )
            self.observersess = keystone_session.Session(auth=auth)
        return self.observersess

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def observerkeystoneclient(self):
        """
        This is a client using the default novaobserver creds. We need this rather than
        the user-specified creds because the user might not have the rights to list
        projects, and we need to list projects in order to determine the domain.
        """
        if not self.observerclient:
            self.observerclient = keystone_client.Client(
                session=self.observersession(),
                interface="public",
                connect_retries=5,
                timeout=300,
            )
        return self.observerclient

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def project_id_for_name(self, project_name):
        if not self.project_ids_for_names or project_name not in self.project_ids_for_names:
            for project in self.allprojects():
                self.project_ids_for_names[project.name] = project.id
        if project_name not in self.project_ids_for_names:
            raise Exception("project name %s not found", project_name)
        return self.project_ids_for_names[project_name]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def project_name_for_id(self, project_id):
        return self.observerkeystoneclient().projects.get(project_id).name

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def keystoneclient(self, project=None):
        if project not in self.keystoneclients:
            session = self.session(project)
            self.keystoneclients[project] = keystone_client.Client(
                session=session, interface="public", connect_retries=5, timeout=300
            )
        return self.keystoneclients[project]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def novaclient(self, project=None, region=None):
        if not project:
            project = self.project

        if not region:
            region = self.region

        if project not in self.novaclients:
            self.novaclients[project] = {}

        if region not in self.novaclients[project]:
            session = self.session(project)
            self.novaclients[project][region] = nova_client.Client(
                "2", session=session, connect_retries=5, timeout=300, region_name=region
            )

        return self.novaclients[project][region]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def glanceclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.glanceclients:
            session = self.session(project)
            self.glanceclients[project] = glanceclient.Client(
                "2", session=session, connect_retries=5, region_name=self.region
            )
        return self.glanceclients[project]

    # In many cases we might be accessing records in one project (e.g. 'noauth-project')
    #  while using a token from a different project (e.g. 'admin').
    # The 'project' arg refers to the project that contains the zones or records of interest.
    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def designateclient(self, auth_project=None, project=None, edit_managed=False):
        if not project:
            project = self.project

        if not auth_project:
            auth_project = self.project

        if project not in self.designateclients:
            session = self.session(auth_project)
            self.designateclients[project] = designateclient.Client(
                session=session,
                timeout=300,
                sudo_project_id=project,
                region_name=self.region,
                edit_managed=edit_managed,
            )
        return self.designateclients[project]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def cinderclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.cinderclients:
            session = self.session(project)
            self.cinderclients[project] = cinderclient.Client(
                session=session, timeout=300, region_name=self.region
            )
        return self.cinderclients[project]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def troveclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.troveclients:
            session = self.session(project)
            self.troveclients[project] = troveclient.Client(
                session=session, timeout=300, region_name=self.region
            )
        return self.troveclients[project]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def neutronclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.neutronclients:
            session = self.session(project)
            self.neutronclients[project] = neutronclient.Client(
                session=session, timeout=300, region_name=self.region
            )
        return self.neutronclients[project]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def allprojects(self):
        client = self.keystoneclient()
        return client.projects.list()

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def allregions(self):
        region_recs = self.keystoneclient().regions.list()
        return [region.id for region in region_recs]

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def allinstances(self, projectid=None, allregions=False):
        instances = []
        if projectid:
            if allregions:
                for region in self.allregions():
                    instances.extend(self.novaclient(projectid, region).servers.list())
            else:
                instances.extend(self.novaclient(projectid).servers.list())
        else:
            search_params = {"all_tenants": True}
            if allregions:
                for region in self.allregions():
                    instances.extend(
                        self.novaclient(projectid, region).servers.list(
                            search_opts=search_params
                        )
                    )
            else:
                instances.extend(
                    self.novaclient(projectid).servers.list(search_opts=search_params)
                )
        return instances

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def allvolumes(self, projectid=None):
        if projectid:
            return self.cinderclient(projectid).volumes.list()
        else:
            search_params = {"all_tenants": True}
            return self.cinderclient(projectid).volumes.list(search_opts=search_params)

    @retry(
        reraise=True,
        stop=stop_after_attempt(9),
        wait=wait_random(min=5, max=15),
        before_sleep=before_sleep_log(logger, logging.WARNING),
    )
    def globalimages(self):
        client = self.glanceclient()
        return [i for i in client.images.list()]


# Alias class for back-compat with old consumers
clients = Clients


class DnsManager(object):
    """Wrapper for communicating with Designate API."""

    def __init__(self, client, tenant="noauth-project"):
        """
        :param client: mwopenstackclients.Clients instance
        :param tenant: Tenant to operate as via X-Auth-Sudo-Tenant-ID
        """
        services = client.keystoneclient().services.list()
        serviceid = [s.id for s in services if s.type == "dns"][0]
        endpoints = client.keystoneclient().endpoints.list(serviceid)
        self.url = [
            e.url
            for e in endpoints
            if e.interface == "public" and e.region == client.region
        ][0]
        session = client.session()
        self.token = session.get_token()
        self.tenant = tenant
        self.designateclient = client.designateclient(
            auth_project=client.project, project=tenant
        )

    def _json_http_kwargs(self, kwargs):
        kwargs["headers"] = {
            "Content-type": "application/json",
        }
        if "data" in kwargs:
            kwargs["data"] = json.dumps(kwargs["data"])
        return kwargs

    def _req(self, verb, *args, **kwargs):
        # Work around lack of X-Auth-Sudo-Tenant-ID support in
        # python-designateclient <2.2.0 with direct use of API.
        map = {
            "GET": requests.get,
            "POST": requests.post,
            "PUT": requests.put,
            "PATCH": requests.patch,
            "DELETE": requests.delete,
        }
        args = list(args)
        args[0] = self.url + args[0]
        headers = kwargs.get("headers", {})
        headers.update(
            {
                "X-Auth-Token": self.token,
                "X-Auth-Sudo-Tenant-ID": self.tenant,
                "X-Designate-Edit-Managed-Records": "true",
            }
        )
        kwargs["headers"] = headers
        kwargs["timeout"] = 300
        r = map[verb.upper()](*args, **kwargs)
        if r.status_code >= 400:
            logging.warning("Error response from %s:\n%s", args[0], r.text)
        r.raise_for_status()
        return r

    def _get(self, *args, **kwargs):
        return self._req("GET", *args, **kwargs)

    def _post(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req("POST", *args, **kwargs)

    def _put(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req("PUT", *args, **kwargs)

    def _delete(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req("DELETE", *args, **kwargs)

    def zones(self, name=None, params=None):
        params = params or {}
        if name:
            params["name"] = name
        r = self._get("/v2/zones", params=params)
        return r.json()["zones"]

    def create_zone(
        self,
        name,
        type_="primary",
        email=None,
        description=None,
        ttl=None,
        masters=None,
        attributes=None,
    ):
        data = {
            "name": name,
            "type": type_,
        }
        if type_ == "primary":
            if email:
                data["email"] = email
            if ttl is not None:
                data["ttl"] = ttl
        elif type_ == "secondary" and masters:
            data["masters"] = masters

        if description is not None:
            data["description"] = description

        if attributes is not None:
            data["attributes"] = attributes
        r = self._post("/v2/zones", data=data)
        return r.json()

    def ensure_zone(
        self,
        name,
        type_="primary",
        email=None,
        description=None,
        ttl=None,
        masters=None,
        attributes=None,
    ):
        """Ensure that a zone exists."""
        r = self.designateclient.zones.list(criterion={"name": name})
        if not r:
            logger.warning("Creating zone %s", name)
            z = self.designateclient.zones.create(
                name, email="root@wmcloud.org", ttl=60
            )
        else:
            z = r[0]
        return z

    def recordsets(self, uuid, name=None, params=None):
        params = params or {}
        if name:
            params["name"] = name
        r = self._get("/v2/zones/{}/recordsets".format(uuid), params=params)
        return r.json()["recordsets"]

    def create_recordset(self, uuid, name, type_, records, description=None, ttl=None):
        data = {
            "name": name,
            "type": type_,
            "records": records,
        }
        if description is not None:
            data["description"] = description
        if ttl is not None:
            data["ttl"] = ttl
        r = self._post("/v2/zones/{}/recordsets".format(uuid), data=data)
        return r.json()

    def update_recordset(self, uuid, rs, records, description=None, ttl=None):
        data = {
            "records": records,
        }
        if description is not None:
            data["description"] = description
        if ttl is not None:
            data["ttl"] = ttl
        r = self._put("/v2/zones/{}/recordsets/{}".format(uuid, rs), data=data)
        return r.json()

    def ensure_recordset(self, zone, name, type_, records, description=None, ttl=None):
        """Find or create a recordest and make sure it matches the given
        records."""
        r = self.designateclient.recordsets.list(zone, criterion={"name": name})
        if not r:
            logger.warning("Creating %s", name)
            rs = self.designateclient.recordsets.create(zone, name, type_, records)
        else:
            rs = r[0]
        if rs["records"] != records:
            logger.info("Updating %s", name)
            rs = self.designateclient.recordsets.update(
                zone, rs["id"], {"records": records}
            )

    def delete_recordset(self, uuid, rs):
        self._delete("/v2/zones/{}/recordsets/{}".format(uuid, rs))
