# Copyright 2015 Hewlett-Packard Development Company, L.P.
#
# Author: Endre Karlson <endre.karlson@hp.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
from keystoneauth1 import adapter

from designateclient import exceptions
from designateclient.v2.blacklists import BlacklistController
from designateclient.v2.limits import LimitController
from designateclient.v2.nameservers import NameServerController
from designateclient.v2.pools import PoolController
from designateclient.v2.quotas import QuotasController
from designateclient.v2.recordsets import RecordSetController
from designateclient.v2.reverse import FloatingIPController
from designateclient.v2.service_statuses import ServiceStatusesController
from designateclient.v2.tlds import TLDController
from designateclient.v2.zones import ZoneController
from designateclient.v2.zones import ZoneExportsController
from designateclient.v2.zones import ZoneImportsController
from designateclient.v2.zones import ZoneTransfersController
from designateclient import version


class DesignateAdapter(adapter.LegacyJsonAdapter):
    """
    Adapter around LegacyJsonAdapter.
    The user can pass a timeout keyword that will apply only to
    the Designate Client, in order:
        - timeout keyword passed to request()
        - timeout attribute on keystone session
    """
    def __init__(self, *args, **kwargs):
        self.timeout = kwargs.pop('timeout', None)
        self.all_projects = kwargs.pop('all_projects', False)
        self.edit_managed = kwargs.pop('edit_managed', False)
        self.sudo_project_id = kwargs.pop('sudo_project_id', None)
        super(self.__class__, self).__init__(*args, **kwargs)

    def request(self, *args, **kwargs):
        kwargs.setdefault('raise_exc', False)

        if self.timeout is not None:
            kwargs.setdefault('timeout', self.timeout)

        kwargs.setdefault('headers', {})

        if self.all_projects:
            kwargs['headers'].setdefault(
                'X-Auth-All-Projects',
                # backported fix from https://review.opendev.org/#/c/390965/
                str(self.all_projects)
            )

        if self.edit_managed:
            kwargs['headers'].setdefault(
                'X-Designate-Edit-Managed-Records',
                self.edit_managed
            )

        if self.sudo_project_id is not None:
            kwargs['headers'].setdefault(
                'X-Auth-Sudo-Project-ID',
                self.sudo_project_id
            )

        kwargs['headers'].setdefault(
            'Content-Type', 'application/json')

        response, body = super(self.__class__, self).request(*args, **kwargs)

        # Decode is response, if possible
        try:
            response_payload = response.json()
        except ValueError:
            response_payload = {}
            body = response.text

        if response.status_code == 400:
            raise exceptions.BadRequest(**response_payload)
        elif response.status_code in (401, 403):
            raise exceptions.Forbidden(**response_payload)
        elif response.status_code == 404:
            raise exceptions.NotFound(**response_payload)
        elif response.status_code == 409:
            raise exceptions.Conflict(**response_payload)
        elif response.status_code >= 500:
            raise exceptions.Unknown(**response_payload)
        return response, body


class Client(object):
    def __init__(self, region_name=None, endpoint_type='publicURL',
                 extensions=None, service_type='dns', service_name=None,
                 http_log_debug=False, session=None, auth=None, timeout=None,
                 endpoint_override=None, all_projects=False,
                 edit_managed=False, sudo_project_id=None):
        if session is None:
            raise ValueError("A session instance is required")

        self.session = DesignateAdapter(
            session,
            auth=auth,
            region_name=region_name,
            service_type=service_type,
            interface=endpoint_type.rstrip('URL'),
            user_agent='python-designateclient-%s' % version.version_info,
            version=('2'),
            endpoint_override=endpoint_override,
            timeout=timeout,
            all_projects=all_projects,
            edit_managed=edit_managed,
            sudo_project_id=sudo_project_id
        )

        self.blacklists = BlacklistController(self)
        self.floatingips = FloatingIPController(self)
        self.limits = LimitController(self)
        self.nameservers = NameServerController(self)
        self.recordsets = RecordSetController(self)
        self.service_statuses = ServiceStatusesController(self)
        self.tlds = TLDController(self)
        self.zones = ZoneController(self)
        self.zone_transfers = ZoneTransfersController(self)
        self.zone_exports = ZoneExportsController(self)
        self.zone_imports = ZoneImportsController(self)
        self.pools = PoolController(self)
        self.quotas = QuotasController(self)
