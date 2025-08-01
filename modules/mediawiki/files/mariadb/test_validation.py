#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""validate tables-catalog.yaml against tables-catalog.schema.json"""

from pathlib import Path

import json
import yaml

from jsonschema import FormatChecker, validate


def test_validation():
    schema_path = Path(__file__).parent / 'tables-catalog.schema.json'
    data_path = Path(__file__).parent / 'tables-catalog.yaml'

    schema = json.load(open(schema_path))
    data = yaml.safe_load(open(data_path))
    validate(data, schema, format_checker=FormatChecker())

    def abbrev(x):
        return {k: x[k] for k in ('name', 'source')}

    # Require 'sources' to be ordered by key
    sourcesKeys = list(data['sources'].keys())
    assert sourcesKeys[0] == 'core', "sources: core goes first"
    for x, y in zip(sourcesKeys[1:], sourcesKeys[2:]):
        assert x <= y, f"sources: {x} and {y} are out of order (order must be alphabetical)"

    # Require all sources listed in 'tables' to also exist in 'sources'
    for x in data['tables']:
        assert x['source'] in sourcesKeys, \
            f"sources: source {x['source']} must be defined in {abbrev(x)}"

    # Require 'tables' to be in the same order as sources
    for x, y in zip(data['tables'][0:], data['tables'][1:]):
        assert sourcesKeys.index(x['source']) <= sourcesKeys.index(y['source']), \
            f"tables: {abbrev(x)} and {abbrev(y)} are out of order (order must match 'sources')"


def test_filtered_tables():
    catalog_path = Path(__file__).parent / 'tables-catalog.yaml'
    catalog = yaml.safe_load(open(catalog_path))

    non_private_tables = []
    private_tables = []
    for table in catalog['tables']:
        if table['visibility'] == 'private':
            private_tables.append(table['name'])
        else:
            non_private_tables.append(table['name'])

    filtered_tables_path = Path(__file__).parent.parent.parent.parent / \
        'role' / 'files' / 'mariadb' / 'filtered_tables.txt'
    with open(filtered_tables_path, 'r') as f:
        for line in f.read().split('\n'):
            if not line.strip():
                continue
            table_name = line.split(',')[0]
            assert table_name not in private_tables, \
                f"Private table {table_name} shouldn't be in filtered_tables.txt"
            assert table_name in non_private_tables, \
                f"{table_name} in filtered_tables.txt must be cataloged"


if __name__ == '__main__':
    try:
        test_validation()
        test_filtered_tables()
    except Exception as e:
        print(e)
