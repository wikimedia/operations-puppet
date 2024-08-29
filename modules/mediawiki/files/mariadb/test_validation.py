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
    assert True
