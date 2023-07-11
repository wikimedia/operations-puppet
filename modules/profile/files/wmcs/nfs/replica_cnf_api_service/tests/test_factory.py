#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

from typing import Any

from replica_cnf_api_service.views import create_app


def get_dummy_config() -> dict[str, Any]:
    return {
        # No TESTING setting
        "TOOLS_PROJECT_PREFIX": "dummyprefix",
        "TOOL_REPLICA_CNF_PATH": "dummypath",
        "PAWS_REPLICA_CNF_PATH": "dummypath",
        "USER_REPLICA_CNF_PATH": "dummypath",
        "BACKENDS": {},
    }


def test_create_app_sets_testing_false_by_default():
    assert not create_app(test_config=get_dummy_config()).testing


def test_create_app_sets_testing_true_when_passed_as_parameter():
    config = get_dummy_config()
    config["TESTING"] = True
    assert create_app(test_config=config).testing
