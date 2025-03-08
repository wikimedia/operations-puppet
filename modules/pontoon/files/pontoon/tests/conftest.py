#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import pytest


def pytest_collection_modifyitems(config, items):
    # Exclude tests marked as 'integration' by default
    if not config.getoption("-m"):  # Only modify if no '-m' option is provided
        skip_integration = pytest.mark.skip(
            reason="Skipping integration tests by default"
        )
        for item in items:
            if "integration" in item.keywords:
                item.add_marker(skip_integration)
