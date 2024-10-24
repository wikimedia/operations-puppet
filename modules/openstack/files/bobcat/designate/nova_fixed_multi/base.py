# SPDX-License-Identifier: Apache-2.0

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


# This is a slight form of the designate source file found at
# designate/notification_handler/base.py

from oslo_config import cfg
from oslo_log import log as logging
from designate.context import DesignateContext
from designate.notification_handler.base import BaseAddressHandler

import wmfdesignatelib

LOG = logging.getLogger(__name__)


class BaseAddressMultiHandler(BaseAddressHandler):
    def _get_ip_data(self, addr_dict):
        ip = addr_dict["address"]
        version = addr_dict["version"]

        data = {
            "ip_version": version,
        }

        # TODO(endre): Add v6 support
        if version == 4:
            data["ip_address"] = ip.replace(".", "-")
            ip_data = ip.split(".")
            for i in [0, 1, 2, 3]:
                data["octet%s" % i] = ip_data[i]
        return data

    def _create_record(
        self, context, name, zone, event_data, addr, resource_type, resource_id
    ):
        recordset_values = {
            "zone_id": zone["id"],
            "name": name,
            "type": "A" if addr["version"] == 4 else "AAAA",
        }

        record_values = {
            "data": addr["address"],
            "managed": True,
            "managed_plugin_name": self.get_plugin_name(),
            "managed_plugin_type": self.get_plugin_type(),
            "managed_resource_type": resource_type,
            "managed_resource_id": resource_id,
        }
        LOG.warn("Creating record in %s with values %r", zone["id"], record_values)

        self.central_api.create_managed_records(
            context, zone['id'],
            records_values=[record_values],
            recordset_values=recordset_values,
        )

    def _create(self, addresses, extra, resource_type=None, resource_id=None):
        """
        Create a record from addresses

        :param addresses: Address objects like
                          {'version': 4, 'ip': '10.0.0.1'}
        :param extra: Extra data to use when formatting the record
        :param resource_type: The managed resource type
        :param resource_id: The managed resource ID
        """
        LOG.debug("Using DomainID: %s" % cfg.CONF[self.name].domain_id)
        zone = self.get_zone(cfg.CONF[self.name].domain_id)
        LOG.debug("Domain: %r" % zone)

        data = extra.copy()
        LOG.debug("Event data: %s" % data)
        data["zone"] = zone["name"]

        context = DesignateContext.get_admin_context(all_tenants=True)

        keystone = wmfdesignatelib.get_keystone_client()
        data["project_id"] = data["tenant_id"]
        data["project_name"] = wmfdesignatelib.project_name_from_id(
            keystone, data["tenant_id"]
        )
        LOG.warning(
            "Looked up project id %s, found project name %s",
            data["project_id"],
            data["project_name"],
        )

        for addr in addresses:
            event_data = data.copy()
            event_data.update(self._get_ip_data(addr))

            if addr["version"] == 4:
                reverse_format = cfg.CONF[self.name].get("reverse_format")
                reverse_zone_id = cfg.CONF[self.name].get("reverse_domain_id")
                if reverse_format and reverse_zone_id:
                    reverse_zone = self.get_zone(reverse_zone_id)
                    LOG.debug("Reverse zone: %r" % reverse_zone)

                    ip_digits = addr["address"].split(".")
                    ip_digits.reverse()
                    name = "%s.in-addr.arpa." % ".".join(ip_digits)

                    recordset_values = {
                        "zone_id": reverse_zone["id"],
                        "name": name,
                        "type": "PTR",
                    }

                    record_values = {
                        "data": reverse_format % event_data,
                        "managed": True,
                        "managed_plugin_name": self.get_plugin_name(),
                        "managed_plugin_type": self.get_plugin_type(),
                        "managed_resource_type": resource_type,
                        "managed_resource_id": resource_id,
                    }

                    LOG.warn(
                        "Creating reverse record in %s with values %r",
                        reverse_zone["id"],
                        record_values,
                    )

                    self.central_api.create_managed_records(
                        context, reverse_zone['id'],
                        records_values=[record_values],
                        recordset_values=recordset_values,
                    )

            names = []
            for fmt in cfg.CONF[self.name].get("format"):
                name = fmt % event_data

                # Avoid duplicates
                if name not in names:
                    names.append(name)
                    self._create_record(
                        context,
                        name,
                        zone,
                        event_data,
                        addr,
                        resource_type,
                        resource_id,
                    )

    def _delete(self, resource_id=None, resource_type="instance", criterion={}):
        """
        Handle a generic delete of a fixed ip within a zone

        :param criterion: Criterion to search and destroy records
        """
        context = DesignateContext().elevated()
        context.all_tenants = True
        context.edit_managed_records = True

        forward_crit = criterion.copy()
        forward_crit.update(
            {
                "zone_id": cfg.CONF[self.name].domain_id,
                "managed": True,
                "managed_plugin_name": self.get_plugin_name(),
                "managed_plugin_type": self.get_plugin_type(),
                "managed_resource_id": resource_id,
                "managed_resource_type": resource_type,
            }
        )
        self.central_api.delete_managed_records(
            context, cfg.CONF[self.name].domain_id, forward_crit
        )

        legacy_zone_id = cfg.CONF[self.name].get("legacy_domain_id")
        if legacy_zone_id:
            legacy_crit = criterion.copy()

            legacy_crit.update(
                {
                    "zone_id": legacy_zone_id,
                    "managed": True,
                    "managed_plugin_name": self.get_plugin_name(),
                    "managed_plugin_type": self.get_plugin_type(),
                    "managed_resource_id": resource_id,
                    "managed_resource_type": resource_type,
                }
            )

            self.central_api.delete_managed_records(
                context, legacy_zone_id, legacy_crit
            )

        reverse_zone_id = cfg.CONF[self.name].get("reverse_domain_id")
        if reverse_zone_id:
            reverse_crit = criterion.copy()
            reverse_crit.update(
                {
                    "zone_id": reverse_zone_id,
                    "managed": True,
                    "managed_plugin_name": self.get_plugin_name(),
                    "managed_plugin_type": self.get_plugin_type(),
                    "managed_resource_id": resource_id,
                    "managed_resource_type": resource_type,
                }
            )

            self.central_api.delete_managed_records(
                context, reverse_zone_id, reverse_crit
            )
