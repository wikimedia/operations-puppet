import os

import glanceclient
from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from keystoneclient.v3 import client as keystone_client
from novaclient import client as nova_client


class clients(object):
    # envfile should be a puppetized environment file like observerenv.sh.
    #
    #  If envfile is not specified, specific creds can be passed in as
    #  username, password, url, project args.  Failing that we fall
    #  back on the environment.
    def __init__(self,
                 envfile="",
                 username="",
                 password="",
                 url="",
                 project=""):
        self.sessions = {}
        self.keystoneclients = {}
        self.novaclients = {}
        self.glanceclients = {}

        if envfile:
            if username or password or url or project:
                raise Exception("envfile is incompatible with specific args")

            with open(envfile) as f:
                for line in iter(f):
                    pieces = line.strip().split("=")
                    if pieces[0].endswith('OS_USERNAME'):
                        self.username = pieces[1].strip('"')
                    if pieces[0].endswith('OS_PASSWORD'):
                        self.password = pieces[1].strip('"')
                    if pieces[0].endswith('OS_AUTH_URL'):
                        self.url = pieces[1].strip('"')
                    if pieces[0].endswith('OS_TENANT_NAME'):
                        self.project = pieces[1].strip('"')
        else:
            if username:
                self.username = username
            else:
                self.username = os.environ.get('OS_USERNAME', None)

            if password:
                self.username = password
            else:
                self.password = os.environ.get('OS_PASSWORD', None)

            if url:
                self.url = url
            else:
                self.url = os.environ.get('OS_AUTH_URL', None)

            if project:
                self.project = project
            else:
                self.project = os.environ.get('OS_TENANT_NAME', None)

        if not self.username:
            raise Exception("No username (env OS_USERNAME) specified")
        if not self.password:
            raise Exception("No password (env OS_PASSWORD) specified")
        if not self.url:
            raise Exception("No url (env OS_AUTH_URL) specified")
        if not self.project:
            raise Exception("No project (env OS_TENANT_NAME) specified")

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
                session=session)
        return self.keystoneclients[project]

    def novaclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.novaclients:
            session = self.session(project)
            self.novaclients[project] = nova_client.Client('2',
                                                           session=session)
        return self.novaclients[project]

    def glanceclient(self, project=None):
        if not project:
            project = self.project

        if project not in self.glanceclients:
            session = self.session(project)
            self.glanceclients[project] = glanceclient.Client('1',
                                                              session=session)
        return self.glanceclients[project]

    def allprojects(self):
        client = self.keystoneclient()
        return client.projects.list()

    def allinstances(self):
        instances = []
        for project in self.allprojects():
            if project.id == 'admin':
                continue
            instances.append(self.novaclient(project.id).servers.list())
        return instances

    def globalimages(self):
        client = self.glanceclient()
        return [i for i in client.images.list()]
