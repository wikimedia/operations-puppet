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

from oslo_config import cfg
from designate.central import rpcapi as central_rpcapi
from designate.context import DesignateContext
from designate.notification_handler.base import BaseAddressHandler
from novaclient import client as novaclient
from oslo_log import log as logging

import pipes
import requests
import subprocess

import wmfdesignatelib

LOG = logging.getLogger(__name__)
central_api = central_rpcapi.CentralAPI()


class BaseAddressWMFHandler(BaseAddressHandler):
    proxy_endpoint = ""
    enc_endpoint = ""

    def _delete(
        self,
        extra,
        managed=True,
        resource_id=None,
        resource_type="instance",
        criterion={},
    ):
        """
        Handle a generic delete of a fixed ip within a zone

        :param criterion: Criterion to search and destroy records
        """

        keystone = wmfdesignatelib.get_keystone_client()

        zone = self.get_zone(cfg.CONF[self.name].domain_id)

        data = extra.copy()
        LOG.debug("Event data: %s" % data)
        data["zone"] = zone["name"]

        data["project_name"] = wmfdesignatelib.project_name_from_id(
            keystone, data["tenant_id"]
        )

        event_data = data.copy()

        fqdn = cfg.CONF[self.name].fqdn_format % event_data
        fqdn = fqdn.rstrip(".")

        region_recs = keystone.regions.list()
        regions = [region.id for region in region_recs]
        if len(regions) > 1:
            # We need to make sure this VM doesn't exist in another region.  If it does
            #  then we don't want to purge anything because we'll break that one.
            for region in regions:
                if region == cfg.CONF[self.name].region:
                    continue
                nova = novaclient.Client(
                    "2",
                    session=wmfdesignatelib.get_keystone_session(data["tenant_id"]),
                    region_name=region,
                )
                servers = nova.servers.list()
                servernames = [server.name for server in servers]
                if event_data["hostname"] in servernames:
                    LOG.warning(
                        "Skipping cleanup of %s because it is also present in region %s"
                        % (fqdn, region)
                    )
                    return

        # Clean puppet keys for deleted instance
        if cfg.CONF[self.name].puppet_master_host:
            LOG.debug("Cleaning puppet key %s" % fqdn)
            self._run_remote_command(
                cfg.CONF[self.name].puppet_master_host,
                cfg.CONF[self.name].certmanager_user,
                "sudo /usr/bin/puppetserver ca clean --certname %s" % pipes.quote(fqdn),
            )

        # Clean up the puppet config for this instance, if there is one
        self._delete_puppet_config(data["tenant_id"], fqdn)

        # For good measure, look around for things associated with the old domain as well
        if cfg.CONF[self.name].legacy_domain_id:
            legacy_zone = self.get_zone(cfg.CONF[self.name].legacy_domain_id)
            legacy_data = data.copy()
            legacy_data["zone"] = legacy_zone["name"]
            legacy_fqdn = cfg.CONF[self.name].fqdn_format % legacy_data
            legacy_fqdn = legacy_fqdn.rstrip(".")
            if cfg.CONF[self.name].puppet_master_host:
                LOG.debug("Cleaning puppet key %s" % legacy_fqdn)
                self._run_remote_command(
                    cfg.CONF[self.name].puppet_master_host,
                    cfg.CONF[self.name].certmanager_user,
                    "sudo puppet cert clean %s" % pipes.quote(legacy_fqdn),
                )

        # Finally, delete any proxy records pointing to this instance.
        #
        # For that, we need the IP which we can dig out of the old DNS record.
        crit = criterion.copy()

        # Make sure we only look at forward records
        crit["zone_id"] = cfg.CONF[self.name].domain_id

        if managed:
            crit.update(
                {
                    "managed": managed,
                    "managed_resource_id": resource_id,
                    "managed_resource_type": resource_type,
                }
            )

        context = DesignateContext().elevated()
        context.all_tenants = True
        context.edit_managed_records = True

        records = central_api.find_records(context, crit)

        if records:
            # We only care about the IP, and that's the same in both records.
            ip = records[0].data
            LOG.debug("Cleaning up proxy records for IP %s" % ip)
            try:
                self._delete_proxies_for_ip(data["project_name"], ip)
            except requests.exceptions.ConnectionError:
                LOG.warning(
                    "Caught exception when deleting proxy records", exc_info=True
                )

    @staticmethod
    def _run_remote_command(server, username, command):
        ssh_command = [
            "/usr/bin/ssh",
            "-o",
            "StrictHostKeyChecking=no",
            "-l%s" % username,
            server,
            command,
        ]

        p = subprocess.Popen(
            ssh_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        (out, error) = p.communicate()
        rcode = p.wait()
        if rcode:
            LOG.warning(
                "Remote command %s failed with output %s and err %s"
                % (ssh_command, out, error)
            )
        return out, error, rcode

    def _delete_puppet_config(self, project, fqdn):
        enc_url, session = self._get_enc_client(project)

        response = session.delete(
            "{}/prefix/{}".format(enc_url, fqdn),
            headers={
                "Accept": "application/json",
            },
            raise_exc=False,
        )
        # no prefix, no problem!
        if response.status_code != 404:
            response.raise_for_status()

    def _delete_proxies_for_ip(self, project, ip):
        project_proxies = self._get_proxy_list_for_project(project)
        for proxy in project_proxies:
            if len(proxy["backends"]) > 1:
                LOG.warning(
                    "This proxy record has multiple backends. "
                    "That's unexpected and not handled, "
                    "we may be leaking proxy records."
                )
            elif proxy["backends"][0].split(":")[1].strip("/") == ip:
                # found match, deleting.
                LOG.debug("Cleaning up proxy record %s" % proxy)
                zone = proxy["domain"]

                proxy_url, session = self._get_proxy_client(project)
                session.delete("{}/mapping/{}".format(proxy_url, zone))

    def _get_proxy_list_for_project(self, project):
        proxy_url, session = self._get_proxy_client(project)
        resp = session.get("{}/mapping".format(proxy_url), raise_exc=False)
        if resp.status_code == 400 and resp.text == "No such project":
            return []
        elif not resp:
            raise Exception("Proxy service request got status " + str(resp.status_code))
        else:
            return resp.json()["routes"]

    def _get_proxy_client(self, project):
        proxy_url = self._get_proxy_endpoint().replace("$(tenant_id)s", project)
        session = wmfdesignatelib.get_keystone_session(project)
        return proxy_url, session

    def _get_proxy_endpoint(self):
        if not self.proxy_endpoint:

            keystone = wmfdesignatelib.get_keystone_client()
            services = keystone.services.list()

            for service in services:
                if service.type == "proxy":
                    serviceid = service.id
                    break

            endpoints = keystone.endpoints.list(
                service=serviceid, region=cfg.CONF[self.name].region
            )
            for endpoint in endpoints:
                if endpoint.interface == "public":
                    self.proxy_endpoint = endpoint.url
                    break

            if not self.proxy_endpoint:
                raise Exception("Can't find the public proxy service endpoint.")

        return self.proxy_endpoint

    def _get_enc_client(self, project):
        proxy_url = self._get_enc_endpoint().replace("$(project_id)s", project)
        session = wmfdesignatelib.get_keystone_session(project)
        return proxy_url, session

    def _get_enc_endpoint(self):
        if not self.enc_endpoint:
            keystone = wmfdesignatelib.get_keystone_client()
            service = keystone.services.list(type="puppet-enc")[0]

            self.enc_endpoint = keystone.endpoints.list(
                service=service.id, interface="public", enabled=True
            )[0].url

        return self.enc_endpoint
