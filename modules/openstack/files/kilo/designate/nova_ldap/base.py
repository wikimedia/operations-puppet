# Copyright 2015 Andrew Bogott for the Wikimedia Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import abc
from oslo_config import cfg
from designate import exceptions
from designate.central import rpcapi as central_rpcapi
from designate.context import DesignateContext
from designate.notification_handler.base import BaseAddressHandler
from designate.plugin import ExtensionPlugin
from keystoneclient.auth.identity import v3
from keystoneclient import client
from keystoneclient import exceptions as keystoneexceptions
from keystoneclient.v3 import projects
from keystoneclient import session
from oslo_log import log as logging

import ldap
import ldap.modlist
import pipes
import subprocess

LOG = logging.getLogger(__name__)
central_api = central_rpcapi.CentralAPI()


class BaseAddressLdapHandler(BaseAddressHandler):
    def _get_ip_data(self, addr_dict):
        ip = addr_dict['address']
        version = addr_dict['version']

        data = {
            'ip_version': version,
        }

        # TODO(endre): Add v6 support
        if version == 4:
            data['ip_address'] = ip.replace('.', '-')
            ip_data = ip.split(".")
            for i in [0, 1, 2, 3]:
                data["octet%s" % i] = ip_data[i]
        return data

    def _getLdapInfo(self, attr, conffile="/etc/ldap.conf"):
        try:
            f = open(conffile)
        except IOError:
            if conffile == "/etc/ldap.conf":
                # fallback to /etc/ldap/ldap.conf, which will likely
                # have less information
                f = open("/etc/ldap/ldap.conf")
        for line in f:
            if line.strip() == "":
                continue
            if line.split()[0].lower() == attr.lower():
                return line.split(None, 1)[1].strip()
                break

    def _initLdap(self):
        self.base = self._getLdapInfo("base")
        self.ldapHost = self._getLdapInfo("uri")
        self.sslType = self._getLdapInfo("ssl")

        self.binddn = cfg.CONF[self.name].get('ldapusername')
        self.bindpw = cfg.CONF[self.name].get('ldappassword')

    def _openLdap(self):
        self.ds = ldap.initialize(self.ldapHost)
        self.ds.protocol_version = ldap.VERSION3
        if self.sslType == "start_tls":
            self.ds.start_tls_s()

        try:
            self.ds.simple_bind_s(self.binddn, self.bindpw)
            return self.ds
        except ldap.CONSTRAINT_VIOLATION:
            LOG.debug("LDAP bind failure:  Too many failed attempts.\n")
        except ldap.INVALID_DN_SYNTAX:
            LOG.debug("LDAP bind failure:  The bind DN is incorrect... \n")
        except ldap.NO_SUCH_OBJECT:
            LOG.debug("LDAP bind failure:  Unable to locate the bind DN account.\n")
        except ldap.UNWILLING_TO_PERFORM, msg:
            LOG.debug("LDAP bind failure:  The LDAP server was unwilling to perform the action requested.\nError was: %s\n" % msg[0]["info"])
        except ldap.INVALID_CREDENTIALS:
            LOG.debug("LDAP bind failure:  Password incorrect.\n")

        return None

    def _closeLdap(self):
        self.ds.unbind()

    def _create(self, addresses, extra, managed=True,
                resource_type=None, resource_id=None):
        """
        Create a a record from addresses

        :param addresses: Address objects like
                          {'version': 4, 'ip': '10.0.0.1'}
        :param extra: Extra data to use when formatting the record
        :param managed: Is it a managed resource
        :param resource_type: The managed resource type
        :param resource_id: The managed resource ID
        """
        self._initLdap()
        if not self._openLdap():
            return

        LOG.debug('Using DomainID: %s' % cfg.CONF[self.name].domain_id)
        domain = self.get_domain(cfg.CONF[self.name].domain_id)
        LOG.debug('Domain: %r' % domain)

        data = extra.copy()
        LOG.debug('Event data: %s' % data)
        data['domain'] = domain['name']

        project_name = self._resolve_project_name(data['tenant_id'])
        data['project_name'] = project_name

        # Just one ldap entry per host, please.
        addr = addresses[0]

        event_data = data.copy()
        event_data.update(self._get_ip_data(addr))
        dc = "%(hostname)s.%(project_name)s.%(domain)s" % event_data
        # ldap doesn't like trailing .s
        dc = dc.rstrip('.').encode('utf8')
        dn = "dc=%s,ou=hosts,dc=wikimedia,dc=org" % dc

        hostEntry = {}
        hostEntry['objectClass'] = ['domainrelatedobject',
                                    'dnsdomain',
                                    'puppetclient',
                                    'domain',
                                    'dcobject',
                                    'top']
        hostEntry['l'] = 'eqiad'
        hostEntry['dc'] = dc
        hostEntry['aRecord'] = addr['address'].encode('utf8')
        hostEntry['puppetClass'] = []
        hostEntry['puppetVar'] = []
        for cls in cfg.CONF[self.name].get('puppetdefaultclasses'):
            hostEntry['puppetClass'].append(cls)
        for var in cfg.CONF[self.name].get('puppetdefaultvars'):
            hostEntry['puppetVar'].append(var)
        hostEntry['associatedDomain'] = []
        hostEntry['puppetVar'].append('instanceproject=%s' %
                                      event_data['project_name'].encode('utf8'))
        hostEntry['puppetVar'].append('instancename=%s' %
                                      event_data['hostname'].encode('utf8'))

        for fmt in cfg.CONF[self.name].get('format'):
            hostEntry['associatedDomain'].append((fmt % event_data).rstrip('.').encode('utf8'))

        if managed:
            LOG.debug('Creating ldap record')

            modlist = ldap.modlist.addModlist(hostEntry)
            try:
                self.ds.add_s(dn, modlist)
            except ldap.LDAPError as e:
                LOG.debug('Ldap exception %s' % e)

        self._closeLdap()

    def _delete(self, extra, managed=True, resource_id=None,
                resource_type='instance', criterion={}):
        """
        Handle a generic delete of a fixed ip within a domain

        :param criterion: Criterion to search and destroy records
        """
        LOG.debug('Initializing ldap')
        self._initLdap()
        if not self._openLdap():
            return

        LOG.debug('Delete using DomainID: %s' % cfg.CONF[self.name].domain_id)
        domain = self.get_domain(cfg.CONF[self.name].domain_id)
        LOG.debug('Domain: %r' % domain)

        data = extra.copy()
        LOG.debug('Event data: %s' % data)
        data['domain'] = domain['name']

        project_name = self._resolve_project_name(data['tenant_id'])
        data['project_name'] = project_name

        event_data = data.copy()

        dc = "%(hostname)s.%(project_name)s.%(domain)s" % event_data
        dc = dc.rstrip('.').encode('utf8')
        dn = "dc=%s,ou=hosts,dc=wikimedia,dc=org" % dc

        LOG.debug('Deleting ldap record: %s' % dn)
        try:
            self.ds.delete_s(dn)
        except ldap.NO_SUCH_OBJECT:
            LOG.debug('Warning:  %s not found in ldap.  Not deleted.' % dn)

        self._closeLdap()

        # WMF-specific add-on:  Clean salt and puppet keys for deleted
        #  instance
        if (cfg.CONF[self.name].puppet_key_format and
                cfg.CONF[self.name].puppet_master_host):
            puppetkey = cfg.CONF[self.name].puppet_key_format % event_data
            puppetkey = puppetkey.rstrip('.').encode('utf8')
            LOG.debug('Cleaning puppet key %s' % puppetkey)
            self._run_remote_command(cfg.CONF[self.name].puppet_master_host,
                                     cfg.CONF[self.name].certmanager_user,
                                     'sudo puppet cert clean %s' % pipes.quote(puppetkey))

        if (cfg.CONF[self.name].salt_key_format and
                cfg.CONF[self.name].salt_master_host):
            saltkey = cfg.CONF[self.name].salt_key_format % event_data
            saltkey = saltkey.rstrip('.').encode('utf8')
            LOG.debug('Cleaning salt key %s' % saltkey)
            self._run_remote_command(cfg.CONF[self.name].salt_master_host,
                                     cfg.CONF[self.name].certmanager_user,
                                     'sudo salt-key -y -d  %s' % pipes.quote(saltkey))

    def _run_remote_command(self, server, username, command):
        ssh_command = ['/usr/bin/ssh', '-l%s' % username, server, command]

        p = subprocess.Popen(ssh_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (out, error) = p.communicate()
        rcode = p.wait()
        return out, error, rcode

        if rcode:
            LOG.warning('Remote call %s to server %s failed: \n%s\n%s' %
                        (command, server, out, error))
            return False
        return True

    def _resolve_project_name(self, tenant_id):
        try:
            username = cfg.CONF[self.name].keystone_auth_name
            passwd = cfg.CONF[self.name].keystone_auth_pass
            project = cfg.CONF[self.name].keystone_auth_project
            url = cfg.CONF[self.name].keystone_auth_url
        except keyerror:
            LOG.debug('Missing a config setting for keystone auth.')
            return

        try:
            auth = v3.Password(auth_url=url,
                               user_id=username,
                               password=passwd,
                               project_id=project)
            sess = session.Session(auth=auth)
            keystone = client.Client(session=sess, auth_url=url)
        except keystoneexceptions.AuthorizationFailure:
            LOG.debug('Keystone client auth failed.')
            return
        projectmanager = projects.ProjectManager(keystone)
        proj = projectmanager.get(tenant_id)
        if proj:
            LOG.debug('Resolved project id %s as %s' % (tenant_id, proj.name))
            return proj.name
        else:
            return 'unknown'
