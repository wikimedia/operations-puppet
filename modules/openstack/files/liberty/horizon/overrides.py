import socket
from urlparse import urlparse

from designatedashboard.dashboards.project.dns_domains import tables as ddtables
from django.utils.translation import ugettext_lazy as _  # noqa
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
