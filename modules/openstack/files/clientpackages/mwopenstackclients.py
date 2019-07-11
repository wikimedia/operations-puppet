import json
import logging
import os
import yaml

import requests

import glanceclient
from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from keystoneclient.v3 import client as keystone_client
from novaclient import client as nova_client
from designateclient.v2 import client as designateclient


class Clients(object):
    """Wrapper class for creating OpenStack clients."""
    def __init__(
        self,
        envfile="",
        username="", password="", url="", project="", region=""
    ):
        """
        Read config from one of:
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

        if envfile:
            if username or password or url or project:
                raise Exception("envfile is incompatible with specific args")

            with open(envfile) as f:
                env = yaml.safe_load(f)
                self.username = env['OS_USERNAME']
                self.password = env['OS_PASSWORD']
                self.url = env['OS_AUTH_URL']
                self.project = env['OS_PROJECT_ID']
                self.region = env['OS_REGION_NAME']
        else:
            if username:
                self.username = username
            else:
                self.username = os.environ.get('OS_USERNAME', None)

            if password:
                self.password = password
            else:
                self.password = os.environ.get('OS_PASSWORD', None)

            if region:
                self.region = region
            else:
                self.region = os.environ.get('OS_REGION_NAME', None)

            if url:
                self.url = url
            else:
                self.url = os.environ.get('OS_AUTH_URL', None)

            if project:
                self.project = project
            else:
                self.project = os.environ.get('OS_PROJECT_ID', None)

        if not self.username:
            raise Exception("No username (env OS_USERNAME) specified")
        if not self.password:
            raise Exception("No password (env OS_PASSWORD) specified")
        if not self.url:
            raise Exception("No url (env OS_AUTH_URL) specified")
        if not self.project:
            raise Exception("No project (env OS_PROJECT_ID) specified")

    def session(self, project=None):
        if not project:
            project = self.project

        if project not in self.sessions:

            auth = generic.Password(
                auth_url=self.url,
                username=self.username,
                password=self.password,
                user_domain_name='Default',
                project_domain_name='Default',
                project_name=project)

            self.sessions[project] = keystone_session.Session(auth=auth)
        return self.sessions[project]

    def keystoneclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.keystoneclients:
            session = self.session(project)
            self.keystoneclients[project] = keystone_client.Client(
                session=session, interface='public', connect_retries=5)
        return self.keystoneclients[project]

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
                '2', session=session, connect_retries=5,
                region_name=region)

        return self.novaclients[project][region]

    def glanceclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.glanceclients:
            session = self.session(project)
            self.glanceclients[project] = glanceclient.Client(
                '1', session=session, connect_retries=5, region_name=self.region)
        return self.glanceclients[project]

    def designateclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.designateclients:
            session = self.session(project)
            self.designateclients[project] = designateclient.Client(
                session=session, sudo_project_id=project, region_name=self.region)
        return self.designateclients[project]

    def allprojects(self):
        client = self.keystoneclient()
        return client.projects.list()

    def allregions(self):
        region_recs = self.keystoneclient().regions.list()
        return [region.id for region in region_recs]

    def allinstances(self, projectid=None, allregions=False):
        instances = []
        if projectid:
            if allregions:
                for region in self.allregions():
                    instances.extend(self.novaclient(projectid, region).servers.list())
            else:
                instances.extend(self.novaclient(projectid).servers.list())
        else:
            for project in self.allprojects():
                if project.id == 'admin':
                    continue
                if allregions:
                    for region in self.allregions():
                        instances.extend(self.novaclient(project.id, region).servers.list())
                else:
                    instances.extend(self.novaclient(project.id).servers.list())
        return instances

    def globalimages(self):
        client = self.glanceclient()
        return [i for i in client.images.list()]


# Alias class for back-compat with old consumers
clients = Clients


class DnsManager(object):
    """Wrapper for communicating with Designate API."""
    def __init__(self, client, tenant='noauth-project'):
        """
        :param client: mwopenstackclients.Clients instance
        :param tenant: Tenant to operate as via X-Auth-Sudo-Tenant-ID
        """
        services = client.keystoneclient().services.list()
        serviceid = [s.id for s in services if s.type == 'dns'][0]
        endpoints = client.keystoneclient().endpoints.list(serviceid)
        self.url = [e.url for e in endpoints
                    if e.interface == 'public' and e.region == client.region][0]
        session = client.session()
        self.token = session.get_token()
        self.tenant = tenant
        self.logger = logging.getLogger('mwopenstackclients.DnsManager')

    def _json_http_kwargs(self, kwargs):
        kwargs['headers'] = {
            'Content-type': 'application/json',
        }
        if 'data' in kwargs:
            kwargs['data'] = json.dumps(kwargs['data'])
        return kwargs

    def _req(self, verb, *args, **kwargs):
        # Work around lack of X-Auth-Sudo-Tenant-ID support in
        # python-designateclient <2.2.0 with direct use of API.
        map = {
            'GET': requests.get,
            'POST': requests.post,
            'PUT': requests.put,
            'PATCH': requests.patch,
            'DELETE': requests.delete,
        }
        args = list(args)
        args[0] = self.url + args[0]
        headers = kwargs.get('headers', {})
        headers.update({
            'X-Auth-Token': self.token,
            'X-Auth-Sudo-Tenant-ID': self.tenant,
            'X-Designate-Edit-Managed-Records': 'true',
        })
        kwargs['headers'] = headers
        r = map[verb.upper()](*args, **kwargs)
        if r.status_code >= 400:
            logging.warning('Error response from %s:\n%s', args[0], r.text)
        r.raise_for_status()
        return r

    def _get(self, *args, **kwargs):
        return self._req('GET', *args, **kwargs)

    def _post(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req('POST', *args, **kwargs)

    def _put(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req('PUT', *args, **kwargs)

    def _delete(self, *args, **kwargs):
        kwargs = self._json_http_kwargs(kwargs)
        return self._req('DELETE', *args, **kwargs)

    def zones(self, name=None, params=None):
        params = params or {}
        if name:
            params['name'] = name
        r = self._get('/v2/zones', params=params)
        return r.json()['zones']

    def create_zone(
        self, name, type_="primary", email=None, description=None,
        ttl=None, masters=None, attributes=None
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
        r = self._post('/v2/zones', data=data)
        return r.json()

    def ensure_zone(
        self, name, type_="primary", email=None, description=None,
        ttl=None, masters=None, attributes=None
    ):
        """Ensure that a zone exists."""
        r = self.zones(name=name)
        if not r:
            self.logger.warning('Creating zone %s', name)
            z = self.create_zone(name, email='root@wmflabs.org', ttl=60)
        else:
            z = r[0]
        return z

    def recordsets(self, uuid, name=None, params=None):
        params = params or {}
        if name:
            params['name'] = name
        r = self._get('/v2/zones/{}/recordsets'.format(uuid), params=params)
        return r.json()['recordsets']

    def create_recordset(
        self, uuid, name, type_, records, description=None, ttl=None
    ):
        data = {
            "name": name,
            "type": type_,
            "records": records,
        }
        if description is not None:
            data["description"] = description
        if ttl is not None:
            data["ttl"] = ttl
        r = self._post('/v2/zones/{}/recordsets'.format(uuid), data=data)
        return r.json()

    def update_recordset(
        self, uuid, rs, records, description=None, ttl=None
    ):
        data = {
            "records": records,
        }
        if description is not None:
            data["description"] = description
        if ttl is not None:
            data["ttl"] = ttl
        r = self._put('/v2/zones/{}/recordsets/{}'.format(uuid, rs), data=data)
        return r.json()

    def ensure_recordset(
        self, zone, name, type_, records, description=None, ttl=None
    ):
        """Find or create a recordest and make sure it matches the given
        records."""
        r = self.recordsets(zone, name=name)
        if not r:
            self.logger.warning('Creating %s', name)
            rs = self.create_recordset(zone, name, type_, records)
        else:
            rs = r[0]
        if rs['records'] != records:
            self.logger.info('Updating %s', name)
            rs = self.update_recordset(zone, rs['id'], records)

    def delete_recordset(self, uuid, rs):
        self._delete('/v2/zones/{}/recordsets/{}'.format(uuid, rs))
