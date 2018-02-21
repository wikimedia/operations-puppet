#!/usr/bin/env python3
"""
Icinga check script to verify that a MediaWiki host's etcd config is in sync with etcd.

It compares the last index of the etcd config exposed via siteinfo on the host with the last index
saved in the given file path to be used as a reference point.

It will return OK if the two indexes match each other, WARNING if the host has a newer index than
the reference one and CRITICAL if it's lower. In all other cases UNKNOWN will be returned.
"""
import argparse
import sys

from enum import IntEnum

import requests


class Nagios(IntEnum):
    OK = 0
    WARNING = 1
    CRITICAL = 2
    UNKNOWN = 3


def parse_args():
    """Parse command line arguments and return them."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'index_file', metavar='INDEX_FILE',
        help=('The file path that stores the etcd current last index for MediaWiki config to '
              'compare with the one in the host.'))
    parser.add_argument('host', metavar='HOST', help='The MediaWiki host to check.')

    return parser.parse_args()


def get_etcd_index(filename):
    """Get and return the current last etcd index for MediaWiki config.

    Arguments:
        filename (str): the file path that stores the etcd current last index for MediaWiki config.

    Returns:
        int: the etcd current last index for MediaWiki config to use as a reference point.

    Raises:
        OSError (and subclasses): for any sort of IO/OS error while reading the file.
        ValueError: if unable to convert the read value to integer.

    """
    with open(filename, 'r') as f:
        return int(f.read().strip())


def main(master_etcd_index, hostname):
    """Run the check, print the result message and return the appropriate Nagios status code.

    Arguments:
        master_etcd_index (int): the etcd current last index for MediaWiki config to compare with
            the one in the host.
        host (str): the hostname where the etcd index must be verified.

    Returns:
        int: the exit code to use, according to the Nagios plugin API requirements.

    Raises:
        requests.exceptions.RequestException: if an error occur during the requests call.
        ValueError: if unable to parse the JSON response.
        KeyError: if the key(s) are not present in the JSON response.

    """
    url = 'http://{host}/w/api.php?action=query&meta=siteinfo&format=json&formatversion=2'.format(
        host=hostname)
    headers = {'X-Forwarded-Proto': 'https', 'Host': 'en.wikipedia.org'}

    response = requests.get(url, headers=headers)
    response.raise_for_status()
    etcd_index = response.json()['query']['general']['wmf-config']['wmfEtcdLastModifiedIndex']

    if etcd_index == master_etcd_index:
        comp = 'matches'
        ret = Nagios.OK
    elif etcd_index > master_etcd_index:
        comp = 'is newer than'
        ret = Nagios.WARNING
    else:
        comp = 'is outdated compared to'
        ret = Nagios.CRITICAL

    print('etcd last index ({index}) {comp} the master one ({master})'.format(
        index=etcd_index, comp=comp, master=master_etcd_index))
    return ret


if __name__ == '__main__':
    try:
        args = parse_args()
        index = get_etcd_index(args.index_file)
        ret = main(index, args.host)
    except Exception as e:
        print('Unable to check etcd last index ({name}): {e}'.format(
            name=e.__class__.__name__, e=e))
        ret = Nagios.UNKNOWN

    sys.exit(ret)
