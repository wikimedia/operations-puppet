#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

#
# Copyright 2021 Wikimedia Foundation
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
Compare signed puppet certs with list of actually existing VMs

Note that this is potentially racy and may misfire for instances that
are already mid-deletion.  In that case it should be safe to re-run.
"""

import argparse
import json
import subprocess

import mwopenstackclients

clients = mwopenstackclients.clients()

# TODO: make this configurable so we can run this in codfw1dev
puppetmaster = "puppetmaster.cloudinfra.wmflabs.org"
puppetmaster_username = "certmanager"
puppetmaster_keyfile = "/var/lib/designate/.ssh/id_rsa"


# this is cribbed from nova_fullstack_test.py:
def run_remote(node, username, keyfile, cmd, debug=False):
    """Execute a remote command using SSH
    :param node: str
    :param cmd: str
    :param debug: bool
    :return: str
    """

    # Possible LogLevel values
    #  QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG
    # NumberOfPasswordPrompts=0 instructs not to
    # accept a password prompt.
    ssh = [
        "/usr/bin/ssh",
        "-o",
        "ConnectTimeout=5",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "NumberOfPasswordPrompts=0",
        "-o",
        "LogLevel={}".format("DEBUG" if debug else "ERROR"),
        "-i",
        keyfile,
        "{}@{}".format(username, node),
    ]

    fullcmd = ssh + cmd.split(" ")

    # The nested nature of the proxycommand line is baffling to
    #  subprocess and/or ssh; joining a full shell commandline
    #  works and gives us something we can actually test by hand.
    return subprocess.check_output(
        " ".join(fullcmd), shell=True, stderr=subprocess.STDOUT
    )


def purge_leaks(delete=False):
    cert_list_output = run_remote(
        puppetmaster,
        puppetmaster_username,
        puppetmaster_keyfile,
        "sudo /usr/bin/puppetserver ca list --all --format json",
    )
    allcerts = [cert['name']
                for cert in json.loads(cert_list_output)['signed']]

    instances = clients.allinstances(allregions=True)
    all_possible_names = []
    all_eqiad_nova_instances_legacy = [
        "%s.%s.eqiad.wmflabs" % (instance.name.lower(), instance.tenant_id)
        for instance in instances
    ]
    all_possible_names.extend(all_eqiad_nova_instances_legacy)
    all_eqiad_nova_instances = [
        "%s.%s.eqiad1.wikimedia.cloud" % (instance.name.lower(), instance.tenant_id)
        for instance in instances
    ]
    all_possible_names.extend(all_eqiad_nova_instances)

    certset = set(allcerts)
    vmset = set(all_possible_names)
    leaks = certset - vmset

    leaklist = sorted(list(leaks))
    for leak in leaklist:
        if leak.endswith("wmflabs") or leak.endswith("wikimedia.cloud"):
            if delete:
                print("Cleaning cert: %s" % leak)
                run_remote(
                    puppetmaster,
                    puppetmaster_username,
                    puppetmaster_keyfile,
                    "sudo /usr/bin/puppetserver ca clean --certname %s" % leak,
                    debug=True,
                )
            else:
                print("Leaked cert: %s" % leak)
        else:
            print("Ignoring weirdly-named cert: %s" % leak)

    if delete:
        print("\nCleaned up %s certs" % len(leaklist))
    else:
        print("\nFound %s leaked certs" % len(leaklist))


parser = argparse.ArgumentParser(
    description="Find (and, optionally, remove) leaked puppet certs."
)
parser.add_argument(
    "--delete", dest="delete", help="Actually delete leaked certs", action="store_true"
)
args = parser.parse_args()

purge_leaks(args.delete)
