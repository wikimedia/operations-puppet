# Copyright 2012 Andrew Bogott for the Wikimedia Foundation
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

from nova import context
from nova import db
from nova import exception
from nova import flags
from nova.image import glance
from nova import log as logging
from nova.openstack.common import cfg
from nova.notifier import api
from nova import utils

LOG = logging.getLogger("nova.notifier.list_notifier")

wiki_opts = [
    cfg.StrOpt('wiki_host',
               default='localhost',
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
               default='keystonelogin',
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
                    help='Event types to always ignore. '
                    'In the event of a conflict, '
                    'this overrides the whitelist.')]

FLAGS = flags.FLAGS
FLAGS.register_opts(wiki_opts)


begin_comment = "<!-- autostatus begin -->"
end_comment = "<!-- autostatus end -->"


class WikiStatus(object):
    """Notifier class which posts instance info to a wiki page.

    Activate with something like this:

    --notification_driver = nova.notifier.list_notifier
    --list_notifier_drivers = nova.wikinotifier.WikiStatus

    (This is a crippled version of this file, specially for essex.)
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

    def __init__(self):
        self.site = None
        self.kclient = {}
        self.tenant_manager = {}
        self.user_manager = {}
        self._wiki_logged_in = False
        self.glance_service = glance.GlanceImageService()

    def _wiki_login(self):
        if not self._wiki_logged_in:
            if not self.site:
                self.site = mwclient.Site(("https", FLAGS.wiki_host),
                                          retry_timeout=5,
                                          max_retries=3)
            if self.site:
                self.site.login(FLAGS.wiki_login,
                                FLAGS.wiki_password, domain=FLAGS.wiki_domain)
                self._wiki_logged_in = True
            else:
                LOG.warning("Unable to reach %s.  We'll keep trying, "
                            "but pages will be out of sync in the meantime.")

    def _keystone_login(self, tenant_id, ctxt):
        if tenant_id not in self.kclient:
            self.kclient[tenant_id] = keystoneclient.Client(token='devstack',
                                                            username=FLAGS.wiki_keystone_login,
                                                            password=FLAGS.wiki_keystone_password,
                                                            tenant_id=tenant_id,
                                                            endpoint=FLAGS.wiki_keystone_auth_url)

            self.tenant_manager[tenant_id] = self.kclient[tenant_id].tenants
            self.user_manager[tenant_id] = self.kclient[tenant_id].users

        return self.kclient[tenant_id]

    def notify(self, message):

        ctxt = context.get_admin_context()
        event_type = message.get('event_type')
        if event_type in FLAGS.wiki_eventtype_blacklist:
            return
        if event_type not in FLAGS.wiki_eventtype_whitelist:
            LOG.debug("Ignoring message type %s" % event_type)
            return

        payload = message['payload']
        instance_name = payload['display_name']
        uuid = payload['instance_id']

        if FLAGS.wiki_instance_dns_domain:
            fqdn = "%s.%s" % (instance_name, FLAGS.wiki_instance_dns_domain)
        else:
            fqdn = instance_name

        template_param_dict = {}
        for field in self.RawTemplateFields:
            template_param_dict[field] = payload[field]

        tenant_id = payload['tenant_id']
        if (FLAGS.wiki_use_keystone and
                self._keystone_login(tenant_id, ctxt)):
            tenant_obj = self.tenant_manager[tenant_id].get(tenant_id)
            user_obj = self.user_manager[tenant_id].get(payload['user_id'])
            tenant_name = tenant_obj.name
            user_name = user_obj.name
            template_param_dict['tenant'] = tenant_name
            template_param_dict['username'] = user_name

        inst = db.instance_get_by_uuid(ctxt, uuid)
        old_school_id = inst.id
        ec2_id = 'i-%08x' % old_school_id

        template_param_dict['cpu_count'] = inst.vcpus
        template_param_dict['disk_gb_current'] = inst.ephemeral_gb
        template_param_dict['host'] = inst.host
        template_param_dict['reservation_id'] = inst.reservation_id
        template_param_dict['availability_zone'] = inst.availability_zone
        template_param_dict['original_host'] = inst.launched_on
        template_param_dict['fqdn'] = fqdn
        template_param_dict['ec2_id'] = ec2_id
        template_param_dict['project_name'] = inst.project_id
        template_param_dict['region'] = FLAGS.wiki_instance_region

        try:
            fixed_ips = db.fixed_ip_get_by_instance(ctxt, old_school_id)
        except exception.FixedIpNotFoundForInstance:
            fixed_ips = []
        ips = []
        floating_ips = []
        for fixed_ip in fixed_ips:
            ips.append(fixed_ip.address)
        for floating_ip in db.floating_ip_get_by_fixed_ip_id(ctxt, fixed_ip.id):
            floating_ips.append(floating_ip.address)

        template_param_dict['private_ip'] = ','.join(ips)
        template_param_dict['public_ip'] = ','.join(floating_ips)

        sec_groups = db.security_group_get_by_instance(ctxt, old_school_id)
        grps = [grp.name for grp in sec_groups]
        template_param_dict['security_group'] = ','.join(grps)

        fields_string = ""
        for key in template_param_dict:
            fields_string += "\n|%s=%s" % (key, template_param_dict[key])

        if event_type == 'compute.instance.delete.start':
            page_string = "\n%s\nThis instance has been deleted.\n%s\n" % (begin_comment,
                                                                           end_comment)
        else:
            page_string = "\n%s\n{{InstanceStatus%s}}\n%s\n" % (begin_comment,
                                                                fields_string,
                                                                end_comment)

        self._wiki_login()
        pagename = "%s%s" % (FLAGS.wiki_page_prefix, ec2_id)
        LOG.debug("wikistatus:  Writing instance info"
                  " to page http://%s/wiki/%s" %
                  (FLAGS.wiki_host, pagename))

        page = self.site.Pages[pagename]
        try:
            pText = page.edit()
            start_replace_index = pText.find(begin_comment)
            if start_replace_index == -1:
                # Just stick it at the end.
                newText = "%s%s" % (page_string, pText)
            else:
                # Replace content between comment tags.
                end_replace_index = pText.find(end_comment, start_replace_index)
                if end_replace_index == -1:
                    end_replace_index = start_replace_index + len(begin_comment)
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
