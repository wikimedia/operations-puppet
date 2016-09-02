# Copyright 2014 Andrew Bogott for the Wikimedia Foundation
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
import sys

import mwclient

from keystoneclient.v2_0 import client as keystoneclient

import nova.context
from nova import exception
from nova import image
from nova import network
from nova import objects
from oslo_log import log as logging
from nova import utils

from oslo.config import cfg
from oslo.messaging.notify import notifier

LOG = logging.getLogger('nova.%s' % __name__)

wiki_opts = [
    cfg.StrOpt('wiki_host',
               default='deployment.wikimedia.beta.wmflabs.org',
               help='Mediawiki host to receive updates.'),
    cfg.StrOpt('wiki_domain',
               default='labs',
               help='wiki domain to receive updates.'),
    cfg.StrOpt('wiki_page_prefix',
               default='InstanceStatus_',
               help='Created pages will have form <prefix>_<instancename>.'),
    cfg.StrOpt('wiki_instance_region',
               default='Unknown',
               help='Hard-coded region name for wiki page.  A bit of a hack.'),
    cfg.StrOpt('wiki_instance_dns_domain',
               default='',
               help='Hard-coded domain for wiki page. E.g. pmtpa.wmflabs'),
    cfg.StrOpt('wiki_login',
               default='login',
               help='Account used to edit wiki pages.'),
    cfg.StrOpt('wiki_password',
               default='password',
               help='Password for wiki_login.'),
    cfg.BoolOpt('wiki_use_keystone',
                default=True,
                help='Indicates whether or not keystone is in use.'),
    cfg.StrOpt('wiki_keystone_auth_url',
               default='http://127.0.0.1:35357/v2.0',
               help='keystone auth url'),
    cfg.StrOpt('wiki_keystone_login',
               default='admin',
               help='keystone admin login'),
    cfg.StrOpt('wiki_keystone_password',
               default='keystonepass',
               help='keystone admin password'),
    cfg.MultiStrOpt('wiki_eventtype_whitelist',
                    default=['compute.instance.delete.start',
                             'compute.instance.create.start',
                             'compute.instance.create.end',
                             'compute.instance.rebuild.start',
                             'compute.instance.rebuild.end',
                             'compute.instance.resize.start',
                             'compute.instance.resize.end',
                             'compute.instance.create_ip.end',
                             'compute.instance.delete_ip.end',
                             'compute.instance.suspend',
                             'compute.instance.resume',
                             'compute.instance.exists',
                             'compute.instance.forcewikistatusupdate',
                             'compute.instance.reboot.start',
                             'compute.instance.reboot.end'],
                    help='Event types to always handle.'),
    cfg.MultiStrOpt('wiki_eventtype_blacklist',
                    default=[],
                    help='Event types to always ignore.'
                    'In the event of a conflict, '
                    'this overrides the whitelist.')]


CONF = cfg.CONF
CONF.register_opts(wiki_opts)


begin_comment = "<!-- autostatus begin -->"
end_comment = "<!-- autostatus end -->"


class WikiStatus(notifier._Driver):
    """Notifier class which posts instance info to a wiki page.
    """

    RawTemplateFields = ['created_at',
                         'disk_gb',
                         'display_name',
                         'instance_id',
                         'instance_type',
                         'launched_at',
                         'memory_mb',
                         'state',
                         'state_description']

    def __init__(self, conf, topics, transport, version=1.0):
        self.host = CONF.wiki_host
        self.site = None
        self.kclient = {}
        self.tenant_manager = {}
        self.user_manager = {}
        self._wiki_logged_in = False
        self._image_service = image.glance.get_default_image_service()

    def _wiki_login(self):
        if not self._wiki_logged_in:
            if not self.site:
                self.site = mwclient.Site(("https", self.host),
                                          retry_timeout=5,
                                          max_retries=3)
            if self.site:
                self.site.login(CONF.wiki_login, CONF.wiki_password,
                                domain=CONF.wiki_domain)
                self._wiki_logged_in = True
            else:
                LOG.warning("Unable to reach %s.  We'll keep trying, "
                            "but pages will be out of sync in the meantime.")

    def _keystone_login(self, tenant_id, ctxt):
        if tenant_id not in self.kclient:
            self.kclient[tenant_id] = keystoneclient.Client(
                token='devstack',
                username=CONF.wiki_keystone_login,
                password=CONF.wiki_keystone_password,
                tenant_id=tenant_id,
                endpoint=CONF.wiki_keystone_auth_url)

            self.tenant_manager[tenant_id] = self.kclient[tenant_id].tenants
            self.user_manager[tenant_id] = self.kclient[tenant_id].users

        return self.kclient[tenant_id]

    def _deserialize_context(self, contextdict):
        context = nova.context.RequestContext(**contextdict)
        return context

    def notify(self, context, message, priority, retry=False):
        ctxt = self._deserialize_context(context)

        event_type = message.get('event_type')
        if event_type in CONF.wiki_eventtype_blacklist:
            return
        if event_type not in CONF.wiki_eventtype_whitelist:
            LOG.debug("Ignoring message type %s" % event_type)
            return

        payload = message['payload']
        instance = payload['instance_id']
        instance_name = payload['display_name']

        template_param_dict = {}
        for field in self.RawTemplateFields:
            template_param_dict[field] = payload[field]

        tenant_id = payload['tenant_id']
        if (CONF.wiki_use_keystone and self._keystone_login(tenant_id,
                                                            ctxt)):
            tenant_obj = self.tenant_manager[tenant_id].get(tenant_id)
            user_obj = self.user_manager[tenant_id].get(payload['user_id'])
            tenant_name = tenant_obj.name
            user_name = user_obj.name
            template_param_dict['tenant'] = tenant_name
            template_param_dict['username'] = user_name

        inst = objects.Instance.get_by_uuid(ctxt, payload['instance_id'])

        simple_id = inst['id']
        ec2_id = 'i-%08x' % simple_id

        if CONF.wiki_instance_dns_domain:
            fqdn = "%s.%s.%s" % (instance_name, inst['project_id'], CONF.wiki_instance_dns_domain)
            resourceName = fqdn
        else:
            fqdn = instance_name
            resourceName = ec2_id

        template_param_dict['cpu_count'] = inst['vcpus']
        template_param_dict['disk_gb_current'] = inst['ephemeral_gb']
        template_param_dict['host'] = inst['host']
        template_param_dict['reservation_id'] = inst['reservation_id']
        template_param_dict['availability_zone'] = inst['availability_zone']
        template_param_dict['original_host'] = inst['launched_on']
        template_param_dict['fqdn'] = fqdn
        template_param_dict['ec2_id'] = ec2_id
        template_param_dict['project_name'] = inst['project_id']
        template_param_dict['region'] = CONF.wiki_instance_region

        ips = []
        floating_ips = []

        try:
            nw_info = network.API().get_instance_nw_info(ctxt, inst)
            ip_objs = nw_info.fixed_ips()
            floating_ip_objs = nw_info.floating_ips()

            ips = [ip['address'] for ip in ip_objs]
            floating_ips = [ip['address'] for ip in floating_ip_objs]
        except exception.FixedIpNotFoundForInstance:
            ips = []
            floating_ips = []

        template_param_dict['private_ip'] = ','.join(ips)
        template_param_dict['public_ip'] = ','.join(floating_ips)

        sec_groups = inst['security_groups']
        grps = [grp['name'] for grp in sec_groups]
        template_param_dict['security_group'] = ','.join(grps)

        if inst['image_ref']:
            try:
                image = self._image_service.show(ctxt, inst['image_ref'])
                image_name = image.get('name', inst['image_ref'])
                template_param_dict['image_name'] = image_name
            except (TypeError):
                template_param_dict['image_name'] = inst['image_ref']
        else:
            template_param_dict['image_name'] = 'tbd'

        fields_string = ""
        for key in template_param_dict:
            fields_string += "\n|%s=%s" % (key, template_param_dict[key])

        clear_page = False
        if event_type == 'compute.instance.delete.start':
            page_string = ("\n%s\nThis instance has been deleted.\n%s\n" %
                           (begin_comment, end_comment))
            clear_page = True
        else:
            page_string = "%s\n{{InstanceStatus%s}}\n%s" % (begin_comment,
                                                            fields_string,
                                                            end_comment)

        self._wiki_login()
        pagename = "%s%s" % (CONF.wiki_page_prefix, resourceName)
        LOG.debug("wikistatus:  Writing instance info"
                  " to page http://%s/wiki/%s" %
                  (self.host, pagename))

        page = self.site.Pages[pagename]
        try:
            pText = page.edit()
            if clear_page:
                newText = page_string
            else:
                start_replace_index = pText.find(begin_comment)
                if start_replace_index == -1:
                    # Just stick new text at the top.
                    newText = "%s\n%s" % (page_string, pText)
                else:
                    # Replace content between comment tags.
                    end_replace_index = pText.find(end_comment,
                                                   start_replace_index)
                    if end_replace_index == -1:
                        end_replace_index = (start_replace_index +
                                             len(begin_comment))
                    else:
                        end_replace_index += len(end_comment)
                    newText = "%s%s%s" % (pText[:start_replace_index],
                                          page_string,
                                          pText[end_replace_index:])
            page.save(newText, "Auto update of instance info.")
        except (mwclient.errors.InsufficientPermission,
                mwclient.errors.LoginError):
            LOG.debug("Failed to update wiki page..."
                      " trying to re-login next time.")
            self._wiki_logged_in = False
