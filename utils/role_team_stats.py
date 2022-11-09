#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
'''
Calculate profile::contacts::role_contacts statistics
'''

from collections import Counter
from statistics import mean, mode, stdev
from pathlib import Path

import yaml

HIERA_DIR = '../hieradata'
ROLE_PATTERN = 'role'


def collect_hiera_files(hiera_dir: str) -> list:
    '''
    A simple function to figure out the relevant hiera files
    '''

    base_path = Path(hiera_dir)
    files = base_path.glob(f'**/{ROLE_PATTERN}/**/*.yaml')
    return files


def process_hiera_files(hiera_files: list) -> (Counter, list):
    '''
    Keep only the ones with actual role_contacts in them and return that data
    '''

    role_contacts = Counter()
    for hiera_file in hiera_files:
        yaml_data = yaml.safe_load(hiera_file.read_text())
        try:
            if yaml_data:
                contacts = yaml_data['profile::contacts::role_contacts']
                role_contacts.update(contacts)
        except KeyError:
            # Unowned role, ignore it.
            pass
    return role_contacts


def calculate_stats(distribution: Counter) -> dict:
    '''
    Calculate some basic stats and return them in a dictionary. Round to 1
    digits after decimal point, just to avoid triggering people
    '''

    # Remove unowned, no point in running stats with it
    result = {}
    data = distribution.values()
    result['mean'] = round(mean(data), 1)
    result['mode'] = mode(data)
    result['max'] = max(data)
    result['min'] = min(data)
    result['stdev'] = round(stdev(data), 1)
    return result


def main():
    '''
    Just a main
    '''

    hiera_files = collect_hiera_files(HIERA_DIR)
    role_contacts = process_hiera_files(hiera_files)

    existing_contacts = '\n    '.join(sorted(role_contacts.keys()))
    print(f'Existing role contacts:\n    {existing_contacts}')
    distribution = role_contacts.most_common()
    distribution_text = '\n    '.join(['%s: %s' % x for x in distribution])
    print(f'Per team roles:\n    {distribution_text}')
    stats = calculate_stats(role_contacts)
    print(f'''Stats:
    Mean: {stats["mean"]}
    Max: {stats["max"]}
    Min: {stats["min"]}
    Mode: {stats["mode"]}
    Sample Standard Deviation: {stats["stdev"]}
    ''')


if __name__ == '__main__':
    main()
