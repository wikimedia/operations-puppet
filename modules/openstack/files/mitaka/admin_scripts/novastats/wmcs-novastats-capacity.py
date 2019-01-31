#!/usr/bin/python
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
Display disk-usage statistics for all compute nodes.

This also queries nova directly in order to compare actual on-disk usage
with potential allocated space.

"""

import mwopenstackclients
import subprocess
import os.path
import collections


ONEGIG = 1024 * 1024 * 1024
ONEMEG = 1024 * 1024

clients = mwopenstackclients.clients()

hosts = clients.novaclient().hosts.list()

computenodedict = {}

flavors = clients.novaclient().flavors.list()
flavordict = {f.id: f.disk for f in flavors}
# extras that our query can't pick up
flavordict['7'] = '80'
flavordict['101'] = '40'
flavordict['bb5bf060-cdbb-4448-b436-a015ae2d4aaf'] = '160'
flavordict['8af1f1cc-d95f-4380-bf10-bcfa0321b10f'] = '60'
flavordict['2d59cc0d-538c-4bbd-b975-8e696a4f7207'] = '80'
flavordict['deea3460-069e-44c7-98ca-ae30bb0de772'] = '80'
flavordict['cc0f1723-38d7-42da-aa2c-cef28d5f4250'] = '300'
flavordict['7447b146-eb66-4ecd-b8c9-ecf480fc6fd1'] = '300'
flavordict['6f43bc6c-c91e-4b4a-8981-dd1d06ec1bb7'] = '300'
flavordict['21e9047d-a60f-499d-b7f5-51f83ddf3611'] = '300'
flavordict['62a89635-8a60-40d7-9b58-56594a071b0a'] = '300'


def printstat(string, alert=False):
    if alert:
        attr = []
        attr.append('31')
        print '\x1b[%sm%s\x1b[0m' % (';'.join(attr), string)
    else:
        print string


all_disk_instances = {}
for host in hosts:
    if host.service == 'compute':
        computenodedict[host.host_name] = {"instances": {}}

        # Learn about CPU usage
        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % host.host_name,
                "mpstat 10 1"]
        r = subprocess.check_output(args)
        for line in r.split('\n'):
            fields = line.split()
            if fields:
                if fields[0] == 'Average:':
                    computenodedict[host.host_name]['cpuidle'] = float(fields[11])

        # Learn about available RAM on this host
        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % host.host_name,
                "free"]
        r = subprocess.check_output(args)
        for line in r.split('\n'):
            fields = line.split()
            if fields:
                if fields[0] == 'Mem:':
                    computenodedict[host.host_name]['freetotal'] = int(fields[1])
                elif fields[0] == '-/+':
                    computenodedict[host.host_name]['freefree'] = int(fields[3])

        # Learn about available space on this host
        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % host.host_name,
                "df"]
        r = subprocess.check_output(args)
        for line in r.split('\n'):
            fields = line.split()
            if len(fields) == 6:
                if os.path.basename(fields[5]) == 'instances':
                    # These are all in k
                    computenodedict[host.host_name]['dfused'] = int(fields[2])
                    computenodedict[host.host_name]['dfavail'] = int(fields[3])
                    computenodedict[host.host_name]['dftotal'] = int(fields[1])

        # Learn about real per instance on-disk usage
        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.eqiad.wmnet" % host.host_name,
                "du -d1 /var/lib/nova/instances"]

        r = subprocess.check_output(args)
        for line in r.split('\n'):
            fields = line.split()
            if not fields:
                continue
            size = fields[0]
            filepath = fields[1]
            filename = os.path.basename(filepath)
            if filename == 'instances':
                computenodedict[host.host_name]['duused'] = int(size)
            if filename == '_base':
                computenodedict[host.host_name]['base'] = int(size)
            elif len(filename.split('-')) == 5:
                # This is an entry for an instance
                computenodedict[host.host_name]['instances'][filename] = int(size)

        computenodedict[host.host_name]['novainstances'] = []

        # Also keep a running list that correlates VMs to virt hosts.
        for instance in computenodedict[host.host_name]['instances'].keys():
            if instance in all_disk_instances:
                all_disk_instances[instance] += [host.host_name]
            else:
                all_disk_instances[instance] = [host.host_name]


fsduplicates = [instance for instance in all_disk_instances.keys()
                if len(all_disk_instances[instance]) > 1]


for instance in fsduplicates:
    printstat("In filesystem twice: %s (%s)" % (instance, all_disk_instances[instance]), True)

instances = clients.allinstances()

all_nova_instances = [instance.id for instance in instances]
for instance in instances:
    if instance.id in all_disk_instances:
        host = all_disk_instances[instance.id][0]
        computenodedict[host]['novainstances'] += [instance]


novaduplicates = [instance for instance, count in
                  collections.Counter(all_nova_instances).items() if count > 1]
if novaduplicates:
    printstat("Instances in nova twice: %s" % novaduplicates, True)

novaset = set(all_nova_instances)
diskset = set(all_disk_instances.keys())

diskstrays = diskset - novaset
for stray in diskstrays:
    printstat("On disk but not in nova: %s on %s" % (stray, all_disk_instances[stray]), True)

novastrays = novaset - diskset
if novastrays:
    printstat("These instances are in nova but can't be found on disk:", True)
    for instance in instances:
        if instance.id in novastrays:
            printstat("%s (%s)" % (instance.id, instance.status), True)

for hostname in computenodedict.keys():
    hostdict = computenodedict[hostname]
    printstat("")
    printstat("== %s == " % hostname)

    instance_space_on_disk = 0
    for instance in hostdict['instances'].keys():
        instance_space_on_disk += hostdict['instances'][instance]

    if 'base' in hostdict:
        accounted_for_space = instance_space_on_disk + hostdict['base']
    else:
        accounted_for_space = instance_space_on_disk

    noninstancespace = hostdict['duused'] - accounted_for_space
    printstat("Space in non-instance files: %sK" % noninstancespace, noninstancespace > ONEMEG)

    missingfilespace = hostdict['dfused'] - hostdict['duused']
    printstat("Space in open but deleted files: %sK" % missingfilespace, missingfilespace > ONEMEG)

    percent = float(hostdict['dfused']) / float(hostdict['dftotal']) * 100
    printstat("%.2f%% filled" % percent, percent > 90)

    maxusage = 0
    for instance in hostdict['novainstances']:
        if instance.flavor['id'] not in flavordict:
            print "flavordict missing %s" % instance.flavor['id']
        else:
            maxusage += int(flavordict[instance.flavor['id']]) * ONEMEG

    percent = float(maxusage) / float(hostdict['dftotal']) * 100
    printstat("Maximum disk commitment: %.2f%%" % percent, percent > 150)

    percent = 100 - float(hostdict['freefree']) / float(hostdict['freetotal']) * 100
    printstat("%.2f%% used RAM" % percent, percent > 90)

    printstat("CPU 10-second idle: %.2f%%" % hostdict['cpuidle'])
