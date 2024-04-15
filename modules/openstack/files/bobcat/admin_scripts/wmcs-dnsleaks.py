#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

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
import sys

import mwopenstackclients

clients = mwopenstackclients.clients(oscloud="novaadmin")

PROMETHEUS_FILE = "/var/lib/prometheus/node.d/designateleaks.prom"

PROM_BLOB = (
    "# HELP cloudvps_designateleaks https://wikitech.wikimedia.org/wiki/Portal:"
    "Cloud_VPS/Admin/Runbooks/Designate_record_leaks\n"
    "# TYPE cloudvps_designateleaks gauge\n"
    "cloudvps_designateleaks {leaks}\n"
)


def write_prom_file(straycount):
    with open(PROMETHEUS_FILE, "w") as f:
        f.write(PROM_BLOB.format(leaks=straycount))


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
    strays = 0
    designateclient = clients.designateclient(project=project_id, edit_managed=True)
    zones = designateclient.zones.list()

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

        recordsets = designateclient.recordsets.list(zone["id"])

        # we need a fresh copy of all instances so we don't accidentally
        #  delete things that have been created since we last checked.
        instances = clients.allinstances(allregions=True)

        all_possible_names = []
        all_eqiad_nova_instances_legacy = [
            "%s.%s.eqiad.wmflabs."
            % (instance.name.lower(), clients.project_name_for_id(instance.tenant_id))
            for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_instances_legacy)
        all_eqiad_nova_instances_project_id = [
            "%s.%s.eqiad1.wikimedia.cloud."
            % (instance.name.lower(), instance.tenant_id)
            for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_instances_project_id)
        all_eqiad_nova_instances_project_name = [
            "%s.%s.eqiad1.wikimedia.cloud."
            % (instance.name.lower(), clients.project_name_for_id(instance.tenant_id))
            for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_instances_project_name)
        all_eqiad_nova_shortname_instances = [
            "%s.eqiad.wmflabs." % (instance.name.lower()) for instance in instances
        ]
        all_possible_names.extend(all_eqiad_nova_shortname_instances)
        all_codfw1dev_nova_instances_project_id = [
            "%s.%s.codfw1dev.wikimedia.cloud."
            % (instance.name.lower(), instance.tenant_id)
            for instance in instances
        ]
        all_possible_names.extend(all_codfw1dev_nova_instances_project_id)
        all_codfw1dev_nova_instances_project_name = [
            "%s.%s.codfw1dev.wikimedia.cloud."
            % (instance.name.lower(), clients.project_name_for_id(instance.tenant_id))
            for instance in instances
        ]
        all_possible_names.extend(all_codfw1dev_nova_instances_project_name)
        all_codfw1dev_nova_instances_legacy = [
            "%s.%s.codfw1dev.cloud."
            % (instance.name.lower(), clients.project_name_for_id(instance.tenant_id))
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
                    strays += 1
                    print(("%s is linked to missing instance %s" % (recordsetid, name)))
                    if delete:
                        designateclient.recordsets.delete(zone["id"], recordsetid)
                # If the instance exists, check to see that it doesn't have multiple IPs.
                if len(recordset["records"]) > 1:
                    strays += 1
                    print(
                        (
                            "A record for %s has multiple IPs: %s"
                            % (name, recordset["records"])
                        )
                    )
                    print(
                        "This needs cleanup but that isn't implemented and almost never happens."
                    )
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
                            strays += 1
                            print(
                                "Found %s ptr recordsets for the same VM: %s %s"
                                % (
                                    len(ptrcounts[record.lower()]),
                                    record,
                                    ptrcounts[record.lower()],
                                )
                            )
                        else:
                            ptrcounts[record.lower()] = [recordset["name"]]

                    else:
                        strays += 1
                        print(
                            (
                                "PTR %s is linked to missing instance %s"
                                % (recordsetid, record)
                            )
                        )
                if not goodrecords:
                    if delete:
                        print("Deleting the whole recordset.")
                        designateclient.recordsets.delete(zone["id"], recordsetid)
                else:
                    if len(goodrecords) != len(originalrecords):
                        if delete:
                            print(
                                (
                                    "Deleting partial recordset: %s vs %s"
                                    % (goodrecords, originalrecords)
                                )
                            )
                            designateclient.update(zone["id"], recordset, goodrecords)
    return strays


parser = argparse.ArgumentParser(
    description="Find (and, optionally, remove) leaked dns records."
)
parser.add_argument(
    "--delete",
    help="Actually delete leaked records",
    action="store_true",
)
parser.add_argument(
    "--to-prometheus",
    help="Write stray record count to prometheus. Cannot be used with --delete",
    action="store_true",
)
args = parser.parse_args()

if args.delete and args.to_prometheus:
    print("--delete and --to-prometheus are mutually exclusive")
    sys.exit(2)

strays = purge_duplicates("cloudinfra", args.delete)
strays += purge_duplicates("cloudinfra-codfw1dev", args.delete)
strays += purge_duplicates("noauth-project", args.delete)

if args.to_prometheus:
    write_prom_file(strays)

sys.exit(0)
