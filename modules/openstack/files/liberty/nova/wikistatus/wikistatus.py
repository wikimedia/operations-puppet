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

import nova.context
from nova import exception
from nova import image
from nova import network
from nova import objects
from oslo_log import log as logging

from oslo_config import cfg
from oslo_messaging.notify import notifier

import pageeditor

LOG = logging.getLogger('nova.%s' % __name__)

wiki_opts = [
    cfg.MultiStrOpt('wiki_eventtype_whitelist',
                    default=['compute.instance.delete.start',
                             'compute.instance.delete.end',
                             'compute.instance.create.start',
                             'compute.instance.create.end',
                             'compute.instance.rebuild.start',
                             'compute.instance.rebuild.end',
                             'compute.instance.resize.start',
                             'compute.instance.resize.end',
                             'compute.instance.create_ip.end',
                             'compute.instance.delete_ip.end',
                             'compute.instance.suspend.end',
                             'compute.instance.resume.end',
                             'compute.instance.shutdown.start',
                             'compute.instance.shutdown.end',
                             'compute.instance.exists',
                             'compute.instance.forcewikistatusupdate',
                             'compute.instance.reboot.start',
                             'compute.instance.reboot.end'],
                    help='Event types to always handle.'),
    cfg.MultiStrOpt('wiki_eventtype_blacklist',
                    default=[],
                    help='Event types to always ignore.'
                    'In the event of a conflict, '
                    'this overrides the whitelist.'),
    cfg.MultiStrOpt('wiki_project_blacklist',
                    default=['contintcloud'],
                    help='Project names to always ignore. Mostly useful for '
                    'projects that use nodepool to manage many instances'),
]


CONF = cfg.CONF
CONF.register_opts(wiki_opts)


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
        self.page_editor = pageeditor.PageEditor()
        self._image_service = image.glance.get_default_image_service()

    def _deserialize_context(self, contextdict):
        context = nova.context.RequestContext(**contextdict)
        return context

    def notify(self, context, message, priority,
               retry=False):
        ctxt = self._deserialize_context(context)

        event_type = message.get('event_type')
        if event_type in CONF.wiki_eventtype_blacklist:
            return
        if event_type not in CONF.wiki_eventtype_whitelist:
            LOG.debug("Ignoring message type %s" % event_type)
            return

        LOG.debug("Handling message type %s" % event_type)

        payload = message['payload']
        instance = payload['instance_id']
        instance_name = payload['display_name']
        project_id = payload['tenant_id']

        if project_id in CONF.wiki_project_blacklist:
            LOG.debug("Ignoring project %s" % project_id)
            return

        template_param_dict = {}
        for field in self.RawTemplateFields:
            template_param_dict[field] = payload[field]

        template_param_dict['username'] = payload['user_id']

        fqdn = "%s.%s.%s" % (instance_name, project_id,
                             CONF.wiki_instance_dns_domain)
        resource_name = fqdn

        if event_type == 'compute.instance.delete.end':
            # No need to gather up instance info, just delete the page
            self.page_editor.edit_page("", resource_name, True)
            return

        inst = objects.Instance.get_by_uuid(ctxt, instance)

        simple_id = inst['id']
        ec2_id = 'i-%08x' % simple_id

        template_param_dict['cpu_count'] = inst['vcpus']
        template_param_dict['disk_gb_current'] = inst['ephemeral_gb']
        template_param_dict['host'] = inst['host']
        template_param_dict['reservation_id'] = inst['reservation_id']
        template_param_dict['availability_zone'] = inst['availability_zone']
        template_param_dict['original_host'] = inst['launched_on']
        template_param_dict['fqdn'] = fqdn
        template_param_dict['ec2_id'] = ec2_id
        template_param_dict['project_name'] = project_id
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
            except (TypeError, exception.ImageNotAuthorized):
                template_param_dict['image_name'] = inst['image_ref']
        else:
            template_param_dict['image_name'] = 'tbd'

        fields_string = ""
        for key in template_param_dict:
            fields_string += "\n|%s=%s" % (key, template_param_dict[key])

        self.page_editor.edit_page(fields_string, resource_name, False)
