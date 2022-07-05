#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# report swift container statistics, by default on stdout and optionally to
# a statsd server via UDP.

import argparse
import os
import re
import sys

import swiftclient

try:
    import statsd
    statsd_found = True
except ImportError:
    statsd_found = False


# map a container set name to a dict of:
#   container_regexp: bucket_name
# each container matching the given regex will have its stats reported under bucket_name
CONTAINER_SETS = {
    # MediaWiki containers used for media storage
    'mw-media': {
        re.compile(r'-thumb(\.[a-z0-9][a-z0-9])?$'):      'thumb',
        re.compile(r'-public(\.[a-z0-9][a-z0-9])?$'):     'originals',
        re.compile(r'-temp(\.[a-z0-9][a-z0-9])?$'):       'temp',
        re.compile(r'-deleted(\.[a-z0-9][a-z0-9])?$'):    'deleted',
        re.compile(r'-transcoded(\.[a-z0-9][a-z0-9])?$'): 'transcoded',
        re.compile(r'-render(\.[a-z0-9][a-z0-9])?$'):     'render',
    },
}


def container_bucket(name, bucket_map):
    for container_re, bucket in bucket_map.items():
        if container_re.search(name):
            return bucket


def main():
    parser = argparse.ArgumentParser(description="Print swift container statistics")
    parser.add_argument('-A', '--auth', dest='auth',
                        default=os.environ.get('ST_AUTH', None),
                        help='URL for obtaining an auth token')
    parser.add_argument('-U', '--user', dest='user',
                        default=os.environ.get('ST_USER', None),
                        help='User name for obtaining an auth token')
    parser.add_argument('-K', '--key', dest='key',
                        default=os.environ.get('ST_KEY', None),
                        help='Key for obtaining an auth token')
    parser.add_argument('--prefix', dest='prefix',
                        default='',
                        help='Prefix to use when reporting metrics')
    parser.add_argument('--container-set', dest='container_set',
                        default='', choices=list(CONTAINER_SETS.keys()),
                        help='Report aggregated container statistics from this set')
    parser.add_argument('--ignore-unknown', dest='ignore_unknown',
                        default=False, action='store_true',
                        help='Do not report unknown containers')
    parser.add_argument('--statsd-host', dest='statsd_host',
                        default='', metavar="HOST",
                        help='Send metrics to this statsd host as well')
    parser.add_argument('--statsd-port', dest='statsd_port',
                        default='8125', metavar="PORT", type=int,
                        help='Send metrics to this statsd port')
    args = parser.parse_args()

    if None in (args.auth, args.user, args.key):
        parser.error("please provide auth, user and key")
        return 1

    if not args.container_set:
        parser.error("please provide a container set")
        return 1

    container_stats = {}
    output_stats = []
    container_buckets = CONTAINER_SETS[args.container_set]

    connection = swiftclient.Connection(args.auth, args.user, args.key)
    headers, containers = connection.get_account(full_listing=True)
    for container in containers:
        bucket = container_bucket(container['name'], container_buckets)
        if bucket is None:
            if not args.ignore_unknown:
                print("Cannot find bucket for container %r" % container['name'], file=sys.stderr)
            continue

        bucket_stats = container_stats.setdefault(
            bucket, {'bytes': 0, 'objects': 0})
        bucket_stats['bytes'] += container['bytes']
        bucket_stats['objects'] += container['count']

    for bucket, stats in container_stats.items():
        for stat in ('bytes', 'objects'):
            prefix = '.'.join([args.prefix, bucket, stat])
            output_stats.append((prefix, stats[stat]))

    for name, value in output_stats:
        print("%s: %s" % (name, value))

    if args.statsd_host:
        if not statsd_found:
            print("statsd module not found, unable to send", file=sys.stderr)
            return 1
        client = statsd.StatsClient(args.statsd_host, args.statsd_port)
        for name, value in output_stats:
            try:
                client.gauge(name, float(value))
            except ValueError:
                print("failed to send %r %r" % (name, value), file=sys.stderr)


if __name__ == '__main__':
    sys.exit(main())
