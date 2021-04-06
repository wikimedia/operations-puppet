# Copyright 2016 Hewlett Packard Enterprise Development Company, L.P.
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
import netaddr
import requests
from oslo_config import cfg
from oslo_log import log as logging
from six.moves import urllib

from designate import exceptions
from designate.backend import base

LOG = logging.getLogger(__name__)
CONF = cfg.CONF


class PDNS4Backend(base.Backend):
    __plugin_name__ = 'pdns4'

    __backend_status__ = 'integrated'

    def __init__(self, target):
        super(PDNS4Backend, self).__init__(target)

        self.api_endpoint = self.options.get('api_endpoint')
        self.api_token = self.options.get('api_token')
        self.tsigkey_name = self.options.get('tsigkey_name', None)

        self.headers = {
            "X-API-Key": self.api_token
        }

    def _build_url(self, zone=''):
        r_url = urllib.parse.urlparse(self.api_endpoint)
        return "%s://%s/api/v1/servers/localhost/zones%s%s" % (
            r_url.scheme, r_url.netloc, '/' if zone else '', zone)

    def _check_zone_exists(self, zone):
        zone = requests.get(
            self._build_url(zone=zone.name),
            headers=self.headers,
        )
        return zone.status_code == 200

    def create_zone(self, context, zone):
        """Create a DNS zone"""

        masters = []
        for master in self.masters:
            host = master.host
            if netaddr.IPAddress(host).version == 6:
                host = '[%s]' % host
            masters.append('%s:%d' % (host, master.port))

        data = {
            "name": zone.name,
            "kind": "slave",
            "masters": masters,

        }
        if self.tsigkey_name:
            data['slave_tsig_key_ids'] = [self.tsigkey_name]

        if self._check_zone_exists(zone):
            LOG.info(
                '%s exists on the server. Deleting zone before creation', zone
            )

            try:
                self.delete_zone(context, zone)
            except exceptions.Backend:
                LOG.error('Could not delete pre-existing zone %s', zone)
                raise

        try:
            requests.post(
                self._build_url(),
                json=data,
                headers=self.headers
            ).raise_for_status()
        except requests.HTTPError as e:
            # check if the zone was actually created - even with errors pdns
            # will create the zone sometimes
            if self._check_zone_exists(zone):
                LOG.info("%s was created with an error. Deleting zone", zone)
                try:
                    self.delete_zone(context, zone)
                except exceptions.Backend:
                    LOG.error('Could not delete errored zone %s', zone)
            raise exceptions.Backend(e)

        self.mdns_api.notify_zone_changed(
            context, zone, self.host, self.port, self.timeout,
            self.retry_interval, self.max_retries, self.delay)

    def delete_zone(self, context, zone):
        """Delete a DNS zone"""

        # First verify that the zone exists -- If it's not present
        #  in the backend then we can just declare victory.
        if self._check_zone_exists(zone):
            try:
                requests.delete(
                    self._build_url(zone.name),
                    headers=self.headers
                ).raise_for_status()
            except requests.HTTPError as e:
                raise exceptions.Backend(e)
        else:
            LOG.warning("Trying to delete zone %s but that zone is not "
                        "present in the pdns backend. Assuming success.",
                        zone)
