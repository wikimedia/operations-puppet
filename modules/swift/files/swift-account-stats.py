#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# report swift account statistics, by default on stdout and optionally to
# a statsd server via UDP

import argparse
import os
import sys

import swiftclient

try:
    import statsd
    statsd_found = True
except ImportError:
    statsd_found = False


def main():
    parser = argparse.ArgumentParser(description="Print swift account statistics")
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
                        help='Prefix to use with the metrics')
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

    account_stats = {}
    output_stats = []

    connection = swiftclient.Connection(args.auth, args.user, args.key)
    headers = connection.head_account()
    account_stats = {
        'containers': headers['x-account-container-count'],
        'objects': headers['x-account-object-count'],
        'bytes': headers['x-account-bytes-used'],
    }

    for key, value in account_stats.items():
        prefix = '.'.join([args.prefix, key])
        output_stats.append((prefix, value))

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
