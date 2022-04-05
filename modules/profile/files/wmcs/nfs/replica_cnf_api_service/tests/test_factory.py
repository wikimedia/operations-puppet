#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
from replica_cnf_api_service.views import create_app


def test_create_app_sets_testing_false_by_default():
    assert not create_app().testing


def test_create_app_sets_testing_true_when_passed_as_parameter():
    assert create_app({"TESTING": True}).testing
