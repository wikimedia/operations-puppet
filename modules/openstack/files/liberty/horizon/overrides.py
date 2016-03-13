from django.core import urlresolvers
from django.utils.translation import ugettext_lazy as _  # noqa

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
from horizon import tables
from designatedashboard.dashboards.project.dns_domains import tables as ddtables


def recordIsProxy(record):
    return record.data == '208.80.155.156'


# Disable the 'edit' and 'delete' button for proxies...
class EditRecord(ddtables.EditRecord):
    def allowed(self, request, record=None):
        if recordIsProxy(record):
            return False
        else:
            return record.type in ddtables.EDITABLE_RECORD_TYPES


class DeleteRecord(ddtables.DeleteRecord):
    def allowed(self, request, record=None):
        if recordIsProxy(record):
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
        return "/project/proxies"

    def allowed(self, request, record=None):
        return recordIsProxy(record)


class RecordsTableWithProxies(ddtables.RecordsTable):
    class Meta(object):
        row_actions = (EditRecord, DeleteRecord, EditProxies)

ddtables.RecordsTable = RecordsTableWithProxies
