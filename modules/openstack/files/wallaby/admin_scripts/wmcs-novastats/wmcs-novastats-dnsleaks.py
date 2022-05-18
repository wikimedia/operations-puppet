#!/usr/bin/python3
#
# Copyright 2017 Wikimedia Foundation
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
"""
Dig through designate records, find and correct inconsistencies.

- Arecs that point to multiple IPs
- Arecs that resolve nova VMs that don't exist anymore
- PTRs for nova VMs that don't exist anymore

Be default this just reports on issues but with the --delete
command it will attempt to clean up as well.


Note that this is potentially racy and may misfire for instances that
are already mid-deletion.  In that case it should be safe to re-run.
"""

import argparse
import time

import requests
import yaml

import mwopenstackclients

clients = mwopenstackclients.clients()


def designate_endpoint_and_token():
    services = clients.keystoneclient().services.list()
    for service in services:
        if service.type == "dns":
            serviceid = service.id
            break
    endpoints = clients.keystoneclient().endpoints.list(serviceid)
    for endpoint in endpoints:
        if endpoint.interface == "public":
            url = endpoint.url

    session = clients.session()
    token = session.get_token()

    return (url, token)


def delete_recordset(endpoint, token, project_id, zoneid, recordsetid):
    headers = {
        "X-Auth-Token": token,
        "X-Auth-Sudo-Tenant-ID": project_id,
        "X-Designate-Edit-Managed-Records": "true",
    }
    recordseturl = "%s/v2/zones/%s/recordsets/%s" % (endpoint, zoneid, recordsetid)
    print(("Deleting %s with %s" % (recordsetid, recordseturl)))
    req = requests.delete(recordseturl, headers=headers, verify=False)
    req.raise_for_status()
    time.sleep(1)


def edit_recordset(endpoint, token, project_id, zoneid, recordset, newrecords):
    headers = {
        "X-Auth-Token": token,
        "X-Auth-Sudo-Tenant-ID": project_id,
        "X-Designate-Edit-Managed-Records": "true",
    }

    patch = {"records": newrecords}

    print(("Updating %s with %s" % (recordset["id"], newrecords)))
    recordseturl = "%s/v2/zones/%s/recordsets/%s" % (endpoint, zoneid, recordset["id"])

    req = requests.put(recordseturl, headers=headers, verify=False, json=patch)
    req.raise_for_status()


def recordset_is_service(recordset):
    if recordset["name"].lower().startswith("k8s."):
        # These are a weird, badly-named service records, not a managed records for
        #  a VM named 'k8s'.
        # Should eventually be unnecesssary once T262562 is resolved
        return True

    if recordset["type"] == "A":
        if ".svc." in recordset["name"].lower():
            return True
        return False

    if recordset["type"] == "PTR":
        for record in recordset["records"]:
            if ".svc." in record.lower():
                return True
    return False


def purge_duplicates(project_id, delete=False):
    (endpoint, token) = designate_endpoint_and_token()

    headers = {"X-Auth-Token": token, "X-Auth-Sudo-Tenant-ID": project_id}

    req = requests.get("%s/v2/zones" % (endpoint), headers=headers, verify=False)
    req.raise_for_status()
    zones = yaml.safe_load(req.text)["zones"]

    for zone in zones:
        if "svc." in zone["name"].lower():
            # We don't want to mess with service records
            print("skipping service zone: %s" % zone["name"])
            continue

        if zone["name"].lower().endswith(".org."):
            # We don't want to mess with user-defined public records
            print("skipping public zone: %s" % zone["name"])
            continue

        print("checking zone: %s" % zone["name"])

        req = requests.get(
            "%s/v2/zones/%s/recordsets" % (endpoint, zone["id"]), headers=headers, verify=False
        )
        req.raise_for_status()
        recordsets = yaml.safe_load(req.text)["recordsets"]

        # we need a fresh copy of all instances so we don't accidentally
        #  delete things that have been created since we last checked.
        instances = clients.allinstances(allregions=True)
        all_possible_names = []
        all_eqiad_nova_instances_legacy = [
            "%s.%s.eqiad.wmflabs." % (instance.name.lower(), instance.tenant_id)
            for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_instances_legacy)
        all_eqiad_nova_instances = [
            "%s.%s.eqiad1.wikimedia.cloud." % (instance.name.lower(), instance.tenant_id)
            for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_instances)
        all_eqiad_nova_shortname_instances = [
            "%s.eqiad.wmflabs." % (instance.name.lower()) for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_shortname_instances)
        all_codfw1dev_nova_instances = [
            "%s.%s.codfw1dev.wikimedia.cloud." % (instance.name.lower(), instance.tenant_id)
            for instance in instances
        ]
        all_possible_names.extend(all_codfw1dev_nova_instances)
        all_codfw1dev_nova_instances_legacy = [
            "%s.%s.codfw1dev.cloud." % (instance.name.lower(), instance.tenant_id)
            for instance in instances
        ]
        all_possible_names.extend(all_codfw1dev_nova_instances_legacy)
        all_codfw1dev_nova_instances_legacy_shortname = [
            "%s.codfw1dev.cloud." % (instance.name.lower()) for instance in instances
        ]
        all_possible_names.extend(all_codfw1dev_nova_instances_legacy_shortname)

        ptrcounts = {}
        for recordset in recordsets:
            name = recordset["name"].lower()
            if recordset_is_service(recordset):
                # These are service records and shouldn't point to instances.
                #  Leave them be.
                continue
            recordsetid = recordset["id"]
            if recordset["type"] == "A":
                # For an A record, we can just delete the whole recordset
                #  if it's for a missing instance.
                if name not in all_possible_names:
                    print(("%s is linked to missing instance %s" % (recordsetid, name)))
                    if delete:
                        delete_recordset(endpoint, token, project_id, zone["id"], recordsetid)
                # If the instance exists, check to see that it doesn't have multiple IPs.
                if len(recordset["records"]) > 1:
                    print(("A record for %s has multiple IPs: %s" % (name, recordset["records"])))
                    print("This needs cleanup but that isn't implemented and almost never happens.")
            elif recordset["type"] == "PTR":
                # Check each record in this set and verify that instances still exist.
                originalrecords = recordset["records"]
                goodrecords = []
                for record in originalrecords:

                    if ".svc." in record:
                        # We don't want to mess with service records
                        print("skipping ptr record for %s" % record)
                        goodrecords += [record]
                        continue

                    if record.endswith(".org."):
                        print("skipping ptr record for %s" % record)
                        goodrecords += [record]
                        continue

                    if record.lower() in all_possible_names:
                        goodrecords += [record]

                        # Make sure we don't have multiple recordsets for the same VM
                        if record.lower() in ptrcounts:
                            ptrcounts[record.lower()].append(recordset["name"])
                            print(
                                "Found %s ptr recordsets for the same VM: %s"
                                % (len(ptrcounts[record.lower()]), ptrcounts[record.lower()])
                            )
                        else:
                            ptrcounts[record.lower()] = [recordset["name"]]

                    else:
                        print(("PTR %s is linked to missing instance %s" % (recordsetid, record)))
                if not goodrecords:
                    if delete:
                        print("Deleting the whole recordset.")
                        delete_recordset(endpoint, token, project_id, zone["id"], recordsetid)
                else:
                    if len(goodrecords) != len(originalrecords):
                        if delete:
                            print(
                                (
                                    "Deleting partial recordset: %s vs %s"
                                    % (goodrecords, originalrecords)
                                )
                            )
                            edit_recordset(
                                endpoint, token, project_id, zone["id"], recordset, goodrecords
                            )


parser = argparse.ArgumentParser(description="Find (and, optionally, remove) leaked dns records.")
parser.add_argument(
    "--delete", dest="delete", help="Actually delete leaked records", action="store_true"
)
args = parser.parse_args()

# We don't want to hear about https certs
requests.packages.urllib3.disable_warnings(
    requests.packages.urllib3.exceptions.InsecureRequestWarning
)

purge_duplicates("cloudinfra", args.delete)
purge_duplicates("cloudinfra-codfw1dev", args.delete)
purge_duplicates("noauth-project", args.delete)
