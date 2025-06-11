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


if __name__ == '__main__':
    try:
        test_validation()
    except Exception as e:
        print(e)
