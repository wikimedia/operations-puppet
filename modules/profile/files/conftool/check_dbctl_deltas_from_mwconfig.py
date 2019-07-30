#!/usr/bin/python3
#
# This script compares the database loadbalancer config as stored in
# db-{codfw.eqiad}.php and served by noc.wikimedia.org versus the same
# configuration as stored in dbctl/etcd.  Temporary monitoring for the
# transition period from the former to the latter, after which it will
# be unnecessary.
#
# See https://wikitech.wikimedia.org/wiki/Dbctl#Configuration_deltas_vs_PHP

import argparse
import json
import requests
import subprocess
import sys

from collections import ChainMap
from enum import IntEnum


def get_mwconfig(dc, noc_url):
    """
    Fetch the configuration as stored in mediawiki-config PHP from noc.wm.o.
    """
    USERAGENT = 'wmf-icinga/check_dbctl_deltas_from_mwconfig (root@wikimedia.org)'
    r = requests.get(noc_url,
                     params={'format': 'json', 'dc': dc},
                     headers={'User-Agent': USERAGENT})
    r.raise_for_status()
    return r.json()


def get_dbctl(dc, dbctl_path):
    """
    Fetch the configuration as specified by dbctl.
    """
    s = subprocess.run([dbctl_path, '--quiet', '-s', dc, 'config', 'get'], stdout=subprocess.PIPE)
    s.check_returncode()
    return json.loads(s.stdout.decode('utf-8'))


class Status(IntEnum):
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3


def main():
    parser = argparse.ArgumentParser(
        description='Nagios check to compare PHP vs dbctl config, see https://w.wiki/6cN',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-d', '--datacenter', required=True,
                        help='very likely codfw or eqiad')
    parser.add_argument('--dbctl-path', default='/usr/bin/dbctl',
                        help='Absolute path to the dbctl tool (useful for local testing)')
    parser.add_argument('--noc-url', default='https://noc.wikimedia.org/db.php',
                        help='URL to db.php on noc (useful for local testing)')
    args = parser.parse_args()

    dbctl = get_dbctl(args.datacenter, dbctl_path=args.dbctl_path)
    mwconfig = get_mwconfig(args.datacenter, noc_url=args.noc_url)

    if mwconfig.keys() != dbctl['sectionLoads'].keys():
        return (Status.CRITICAL, "Mismatched sets of sections: {}".format(
            mwconfig.keys() ^ dbctl['sectionLoads'].keys()))

    for section in mwconfig.keys():
        # Check that the masters are the same.
        mwconfig_master = mwconfig[section]['hosts'][0]
        dbctl_master = list(dbctl['sectionLoads'][section][0].keys())[0]
        if (mwconfig_master != dbctl_master):
            return (Status.CRITICAL,
                    'Mismatched masters for section {}: PHP {} vs dbctl {}'.format(
                        section, mwconfig_master, dbctl_master))

        # Check that the sectionLoads are the same.
        mwconfig_loads = mwconfig[section]['loads']
        dbctl_loads = dict(ChainMap(*(dbctl['sectionLoads'][section])))
        if (mwconfig_loads != dbctl_loads):
            return (Status.CRITICAL,
                    'Mismatched loads for section {}: diff {} -- PHP {} vs dbctl {}'.format(
                        section,
                        mwconfig_loads.items() ^ dbctl_loads.items(),
                        mwconfig_loads, dbctl_loads))

        # Check that group loads are the same.
        mwconfig_grouploads = mwconfig[section]['groupLoads']  # Will be a dict or None.
        dbctl_grouploads = dbctl['groupLoadsBySection'].get(section, None)
        if (mwconfig_grouploads != dbctl_grouploads):
            return (Status.CRITICAL,
                    'Mismatched groupLoads for section {}: diff {} -- PHP {} vs dbctl {}'.format(
                        section,
                        mwconfig_grouploads.items() ^ dbctl_grouploads.items(),
                        mwconfig_grouploads, dbctl_grouploads))

        # Check that read-only status is the same.
        mwconfig_readonly = mwconfig[section]['readOnly']  # Will be False or a string reason.
        dbctl_readonly = dbctl['readOnlyBySection'].get(section, False)
        if (mwconfig_readonly != dbctl_readonly):
            return (Status.CRITICAL,
                    'Mismatched readOnly for section {}: PHP {} vs dbctl {}'. format(
                        section, mwconfig_readonly, dbctl_readonly))

    return (Status.OK, "OK: configurations match")


if __name__ == '__main__':
    rv, message = main()
    print(message)
    sys.exit(rv)
