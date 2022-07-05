#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

# report swift dispersion statistics, by default on stdout and optionally to
# a statsd server via UDP

import argparse
import json
import subprocess
import sys

try:
    import statsd
    statsd_found = True
except ImportError:
    statsd_found = False


def main():
    parser = argparse.ArgumentParser(description="Print swift dispersion statistics")
    parser.add_argument('--prefix', dest='prefix', default='',
                        help='Prefix to use with the metrics')
    parser.add_argument('--statsd-host', dest='statsd_host', default='', metavar="HOST",
                        help='Send metrics to this statsd host as well')
    parser.add_argument('--statsd-port', dest='statsd_port', default='8125',
                        metavar="PORT", type=int, help='Send metrics to this statsd port')
    parser.add_argument('--policy-name', dest='policy_name', default=None, metavar="NAME",
                        help='Use the storage policy NAME')
    args = parser.parse_args()

    dispersion_stats = {}

    try:
        report_command = ['swift-dispersion-report', '--dump-json']
        if args.policy_name:
            report_command.extend(['--policy-name', args.policy_name])
        output = subprocess.check_output(report_command)
    except subprocess.CalledProcessError as e:
        print('%r failed %s: %r' % (
            report_command, e.returncode, e.output), file=sys.stderr)
        return e.returncode

    try:
        json_data = output.decode('utf8')
        if 'Using storage policy:' in json_data:
            _, json_data = json_data.splitlines()
        json_stats = json.loads(json_data)
    except ValueError:
        print('failed to load json from %r' % output, file=sys.stderr)
        return 1

    # {"object": {
    #    "retries": 0, "missing_0": 1304, "copies_expected": 2608,
    #    "pct_found": 100.0, "overlapping": 6, "copies_found": 2608
    #   },
    #  "container": {
    #    "retries": 0, "copies_expected": 2606, "pct_found": 100.0,
    #    "overlapping": 8, "copies_found": 2606
    #   }}
    for ring, stat in json_stats.items():
        for name, value in stat.items():
            key = '.'.join([args.prefix, ring, name])
            dispersion_stats[key] = value

    for key, value in dispersion_stats.items():
        print("%s: %s" % (key, value))

    if args.statsd_host:
        if not statsd_found:
            print("statsd module not found, unable to send", file=sys.stderr)
            return 1
        client = statsd.StatsClient(args.statsd_host, args.statsd_port)
        for key, value in dispersion_stats.items():
            try:
                client.gauge(key, float(value))
            except ValueError:
                print("failed to send %r %r" % (key, value), file=sys.stderr)


if __name__ == '__main__':
    sys.exit(main())
