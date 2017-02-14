import socket
from urlparse import urlparse

from designatedashboard.dashboards.project.dns_domains import tables as ddtables
from django.utils.translation import ugettext_lazy as _  # noqa
from django.conf import settings
from horizon import tables
from openstack_dashboard.api import keystone

#  --  Tidy up the instance creation panel  --

from openstack_dashboard.dashboards.project.instances.workflows import create_instance
#  Remove a couple of unwanted tabs from the instance creation panel:
#   PostCreationStep just provides confusing competition with puppet.
#   SetAdvanced provides broken features like configdrive and partitioning.

create_instance.LaunchInstance.default_steps = (create_instance.SelectProjectUser,
                                                create_instance.SetInstanceDetails,
                                                create_instance.SetAccessControls,
                                                create_instance.SetNetwork)


# Disable the UpdateInstanceInfo tab.  All that supports is instance renaming, which is
#  risky and breaks compatibility with wikitech.
from openstack_dashboard.dashboards.project.instances.workflows import update_instance
# Previously (UpdateInstanceInfo, UpdateInstanceSecurityGroups)
update_instance.UpdateInstance.default_steps = (update_instance.UpdateInstanceSecurityGroups,)

#  --  Support proxy records in the designate dashboard  --


# In the designate dashboard, we have some records that are special
#  and maanged by the proxy dashboard.  We need to remove the edit/delete
#  buttons for those records and instead add a button that jumps to
#  the proxy panel.

PROXYIP = None


def recordIsProxy(request, record):
    global PROXYIP
    if not PROXYIP:
        # Leap of faith:  Assume the proxy-api host is also the proxy host.
        #  So, get the proxy endpoint from keystone, convert to an IP,
        #  and compare to 'record'

        client = keystone.keystoneclient(request)
        services = client.services.list()

        proxyservices = [service for service in services if service.name == 'proxy']
        endpoints = client.endpoints.list(service=proxyservices[0].id)
        proxyurl = endpoints[0].url

        parsed_uri = urlparse(proxyurl)
        domain = parsed_uri.hostname
        PROXYIP = socket.gethostbyname_ex(domain)[2][0]

    return record.data == PROXYIP


# Disable the 'edit' and 'delete' button for proxies...
class EditRecord(ddtables.EditRecord):

    def allowed(self, request, record=None):
        if recordIsProxy(request, record):
            return False
        else:
            return record.type in ddtables.EDITABLE_RECORD_TYPES


class DeleteRecord(ddtables.DeleteRecord):

    def allowed(self, request, record=None):
        if recordIsProxy(request, record):
            return False
        else:
            return record.type in ddtables.EDITABLE_RECORD_TYPES


# And put an 'edit proxies' button in their place
class EditProxies(tables.LinkAction):
    '''Link action for a record created by the dynamic proxy panel.'''
    name = "edit_proxies"
    verbose_name = _("Edit Proxies")
    classes = ("btn-edit")
    policy_rules = (("dns", "update_record"),)

    def get_link_url(self, datum=None):
        return "/project/proxy"

    def allowed(self, request, record=None):
        return recordIsProxy(request, record)


class RecordsTableWithProxies(ddtables.RecordsTable):

    class Meta(object):
        name = "records"
        verbose_name = _("Records")
        table_actions = (ddtables.CreateRecord,)
        row_actions = (EditRecord, DeleteRecord, EditProxies)
        multi_select = False


ddtables.RecordsTable = RecordsTableWithProxies


#  --  Fix a bug in quota calculations, T142379 --
from openstack_dashboard.api import base
from openstack_dashboard.api import nova
from horizon import exceptions


def _get_tenant_compute_usages_fixed(request, usages, disabled_quotas, tenant_id):
    # Unlike the other services it can be the case that nova is enabled but
    # doesn't support quotas, in which case we still want to get usage info,
    # so don't rely on '"instances" in disabled_quotas' as elsewhere
    if not base.is_service_enabled(request, 'compute'):
        return

    if tenant_id:
        # determine if the user has permission to view across projects
        # there are cases where an administrator wants to check the quotas
        # on a project they are not scoped to
        instances, has_more = nova.server_list(
            request, search_opts={'tenant_id': tenant_id})
    else:
        instances, has_more = nova.server_list(request)

    # Fetch deleted flavors if necessary.
    flavors = dict([(f.id, f) for f in nova.flavor_list(request)])
    missing_flavors = [instance.flavor['id'] for instance in instances
                       if instance.flavor['id'] not in flavors]
    for missing in missing_flavors:
        if missing not in flavors:
            try:
                flavors[missing] = nova.flavor_get(request, missing)
            except Exception:
                flavors[missing] = {}
                exceptions.handle(request, ignore=True)

    usages.tally('instances', len(instances))

    # Sum our usage based on the flavors of the instances.
    for flavor in [flavors[instance.flavor['id']] for instance in instances]:
        usages.tally('cores', getattr(flavor, 'vcpus', None))
        usages.tally('ram', getattr(flavor, 'ram', None))

    # Initialize the tally if no instances have been launched yet
    if len(instances) == 0:
        usages.tally('cores', 0)
        usages.tally('ram', 0)

from openstack_dashboard.usage import quotas
quotas._get_tenant_compute_usages = _get_tenant_compute_usages_fixed


# Backport a fix which evaulates policy rules improperly
# https://bugs.launchpad.net/horizon/+bug/1653792
def _can_access_fixed(self, request):
    policy_check = getattr(settings, "POLICY_CHECK_FUNCTION", None)

    # this check is an OR check rather than an AND check that is the
    # default in the policy engine, so calling each rule individually
    if policy_check and self.policy_rules:
        for rule in self.policy_rules:
            rule_param = rule
            if not any(isinstance(r, (list, tuple)) for r in rule):
                rule_param = (rule,)
            if policy_check(rule_param, request):
                return True
        return False

    # default to allowed
    return True

from horizon import base as horizonbase
horizonbase.HorizonComponent._can_access = _can_access_fixed
