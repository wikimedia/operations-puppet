#!/usr/bin/python
"""
Simple NRPE check script that checks if a particular projects' critical
instance types are spread out enough in underlying virt* hosts so that
a virt host outage doesn't take out all instances in a given class.

Note that the algorithm used for checking 'spread out enough' is super
bogus, and doesn't work when number of instances > number of virt hosts.
This should be fixed - it isn't even good enough for some of the host
classes in the test use case (Toolforge' exec nodes).
FIXME: Find a mathematically valid definition of 'spread out enough'
       and implement it
"""
import sys
import argparse
import yaml
from novaclient import client as novaclient
from collections import defaultdict


def classify_instances(creds, project, classifier):
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
    client = novaclient.Client("1.1", project_id=project, **creds)

    servers = client.servers.list()
    classification = defaultdict(list)

    for server in servers:
        if getattr(server, 'status') != 'ACTIVE':
            continue
        name, host = server.name, getattr(server, 'hostId')
        for prefix in classifier:
            if name.startswith(project + '-' + prefix):
                classname = classifier[prefix]
                classification[classname].append((name, host))
                break

    return classification


def get_failed_classes(classification):
    """
    Return list of classes that are not 'spread out enough'

    'Spread out enough' is defined very, very poorly - it just
    checks that:
        number of instances > unique number of virt* hosts hosting instances

    This works only when number of instances > total number of virt* hosts,
    and is also quite terrible otherwise.

    FIXME: Use a proper mathematical definition of 'spread out enough'.

    Returns a list of classes that are considered to be not spread out enough
    """
    failed_classes = []

    for cls, items in classification.iteritems():
        hosts_used = len(set([i[1] for i in items]))
        if hosts_used < len(items):
            failed_classes.append(cls)
    return failed_classes


if __name__ == '__main__':
    argparser = argparse.ArgumentParser()
    argparser.add_argument(
        '--config',
        help='Path to yaml config file',
        type=argparse.FileType('r')
    )
    args = argparser.parse_args()

    config = yaml.safe_load(args.config)

    classification = classify_instances(config['credentials'],
                                        config['project'],
                                        config['classifier'])
    failed_classes = get_failed_classes(classification)
    if failed_classes:
        print "CRITICAL: %s class instances not spread out enough" % \
            ','.join(failed_classes)
        sys.exit(2)
    else:
        print "OK: All critical toolforge instances are spread out enough"
        sys.exit(0)
