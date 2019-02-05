#!/usr/bin/python
#
# Copyright (c) 2019 Wikimedia Foundation and contributors
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
Simple NRPE check script that checks if a particular projects' critical
instance types are spread out enough in underlying virt* hosts so that
a virt host outage doesn't take out all instances in a given class.

Our current definition of 'spread out enough' is no more than 1/3 of the
instances of a given class on the same virt.
"""
from __future__ import print_function

import argparse
import collections
import logging
import math
import sys

import mwopenstackclients
import yaml


logger = logging.getLogger(__name__)


def classify_instances(project, servers, classifier):
    """
    Classify instances in project based on prefixes.

    Uses the Nova API (accessed with passed in creds variable) to get
    a list of instances in the given project, and then classifies
    them based on a simple prefixs based algorithm, with data in the
    classifier.

    classifer is a dictionary of prefix -> classname. Each instance
    that matches $project-$prefix-* is assigned the classname. If
    none match, the node is not classified.

    Returns a dict with the following structure:
        classname  -> [(instancename, virthostname)]
    """
    classification = {}
    for prefix in classifier:
        classification[classifier[prefix]] = []

    for server in servers:
        if getattr(server, 'status') != 'ACTIVE':
            continue
        name = server.name
        host = getattr(server, 'OS-EXT-SRV-ATTR:hypervisor_hostname')
        for prefix in classifier:
            if name.startswith('{}-{}'.format(project, prefix)):
                classname = classifier[prefix]
                classification[classname].append((name, host))
                break

    return classification


def get_failed_classes(classification):
    """Get list of classes that are not 'spread out enough'.

    'Spread out enough' is defined as no more than 1/3 of the total instances
    on a single virt.
    """
    failed_classes = []

    for cls, items in classification.iteritems():
        num_instances = len(items)
        buckets = collections.defaultdict(list)
        for name, host in items:
            buckets[host].append(name)
        hosts_used = len(buckets)
        logger.debug('%s: %d on %d virts', cls, num_instances, hosts_used)

        max_instances = int(math.ceil(num_instances / 3.0))
        for virt, instances in buckets.iteritems():
            instance_cnt = len(instances)
            if instance_cnt > max_instances:
                logger.info(
                    '%s: %d instances on %s; expected <=%d',
                    cls, instance_cnt, virt, max_instances)
                failed_classes.append(cls)
                break

    return failed_classes


def main():
    parser = argparse.ArgumentParser(description='Instance distribution check')
    parser.add_argument(
        '-v', '--verbose', action='count',
        default=0, dest='loglevel', help='Increase logging verbosity')
    parser.add_argument(
        '--envfile', default='/etc/novaobserver.yaml',
        help='Path to OpenStack authentication YAML file')
    parser.add_argument(
        '--config', type=argparse.FileType('r'),
        help='Path to yaml config file')

    args = parser.parse_args()

    logging.basicConfig(
        level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
        format='%(asctime)s %(name)-12s %(levelname)-8s: %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%SZ'
    )
    logging.captureWarnings(True)
    # Quiet some noisy 3rd-party loggers channels
    logging.getLogger('requests').setLevel(logging.WARNING)
    logging.getLogger('urllib3').setLevel(logging.WARNING)

    config = yaml.safe_load(args.config)
    client = mwopenstackclients.Clients(envfile=args.envfile)

    classification = classify_instances(
        project=config['project'],
        servers=client.allinstances(
            projectid=config['project'], allregions=True),
        classifier=config['classifier'])
    failed_classes = get_failed_classes(classification)

    if failed_classes:
        print(
            "CRITICAL: {} class instances not spread out enough".format(
                ','.join(failed_classes)))
        return 2
    else:
        print("OK: All critical toolforge instances are spread out enough")
        return 1


if __name__ == '__main__':
    sys.exit(main())
