#!/usr/bin/env python3

# export grafana dashboard JSON description for revision control
# pretty printing and sorting the JSON representation should minimise
# differences when code-reviewing changes

import argparse
import json
import logging
import sys
from urllib.parse import urlparse, urlunparse

import requests

log = logging.getLogger(__name__)


def dump_dashboard(url, tags=None):
    parsed = urlparse(url)
    name, uid = get_name_and_uid(parsed)
    api_url = urlunparse(
        (parsed.scheme, parsed.netloc, '/api/dashboards/uid/{}'.format(uid), '', '', '')
    )

    req = requests.get(api_url, headers={'Content-Type': 'application/json'})
    req.raise_for_status()

    dashboard = req.json()['dashboard']

    if tags:
        for tag in tags:
            if tag not in dashboard['tags']:
                dashboard['tags'].append(tag)

    log.info('dumping %s into %s', url, name)
    with open(name, 'w') as f:
        json.dump(dashboard, f, sort_keys=True,
                  separators=(',', ': '), indent=2)


def get_name_and_uid(parsed):
    uid, name = parsed.path.split('/')[-2:]
    if not uid or not len(uid) == 9 or not name:
        raise ValueError('Provided url is missing either uid or name.  '
                         'Expected form: https://grafana.wikimedia.org/d/000000001/dashboard-name')
    # when saved to disk we might add .json extension, strip it
    if name.endswith('.json'):
        name = name[:-5]
    return name, uid


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dashboard',
                        help='Dashboard url '
                             '(e.g. https://grafana.wikimedia.org/d/000000001/dashboard-name)',
                        action='append',
                        nargs='+')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    for url in args.dashboard[0]:
        dump_dashboard(url, tags=['source:puppet.git', 'readonly'])


if __name__ == '__main__':
    sys.exit(main())
