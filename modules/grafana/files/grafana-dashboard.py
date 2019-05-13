#!/usr/bin/env python

# export grafana dashboard JSON description for revision control
# pretty printing and sorting the JSON representation should minimise
# differences when code-reviewing changes

import argparse
import json
import logging
import re
import sys

import requests

DEFAULT_URL = 'https://grafana.wikimedia.org/api/dashboards/db/%s'

log = logging.getLogger(__name__)


def dump_dashboard(url, tags=None):
    if '/' not in url:
        url = DEFAULT_URL % url
    # non-API url, convert to API
    elif '/dashboard/' in url:
        url = re.sub('/dashboard/', '/api/dashboards/', url)

    name = url.split('/')[-1]

    # when saved to disk we might add .json extension, strip it
    if name.endswith('.json'):
        name = re.sub(r'\.json$', '', name)

    req = requests.get(url)
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


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dashboard', help='URL or dashboard name to act on',
                        action='append', nargs='+')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    for url in args.dashboard[0]:
        dump_dashboard(url, tags=['source:puppet.git', 'readonly'])


if __name__ == '__main__':
    sys.exit(main())
