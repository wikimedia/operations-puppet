#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

import json
import os
from configparser import ConfigParser
from configparser import Error as ConfigParserError
from pathlib import Path

import pytest
from replica_cnf_api_service.backends.common import get_command_array, mysql_hash
from replica_cnf_api_service.views import DRY_RUN_PASSWORD, DRY_RUN_USERNAME
from requests_mock import Mocker

from .conftest import (
    ACCOUNT_ID,
    PASSWORD,
    TOOL_ACCOUNT_ID,
    UID,
    USERNAME,
    WRONG_ACCOUNT_ID,
    WRONG_TOOL_ACCOUNT_ID,
)


def test_mysql_hash():
    expected_hash = "*4414e26eded6d661b5386813ebba95065dbc4728"
    password = "test_password"
    assert mysql_hash(password) == expected_hash


@pytest.mark.parametrize(
    "script", ["write_replica_cnf.sh", "read_replica_cnf.sh", "delete_replica_cnf.sh"]
)
def test_get_command_array(app, script):
    scripts_path = Path(app.config["TESTONLY_SCRIPTS_PATH"])
    expected_script_path = str(scripts_path / script)

    command_array = get_command_array(script=script, scripts_path=scripts_path, use_sudo=False)
    assert isinstance(command_array, list)
    assert len(command_array) == 1
    assert command_array[0] == expected_script_path

    command_array = get_command_array(script=script, scripts_path=scripts_path, use_sudo=True)
    assert isinstance(command_array, list)
    assert len(command_array) == 3
    assert command_array[0] == "sudo"
    assert command_array[1] == "--preserve-env=CONF_FILE"
    assert command_array[2] == expected_script_path


def test_fetch_paws_uids_success(client):
    response = client.get("/v1/paws-uids")
    response_data = json.loads(response.data)
    assert response.status_code == 200
    assert response_data["result"] == "ok"
    assert isinstance(response_data["detail"]["paws_uids"], list)
    assert response_data["detail"]["paws_uids"][0] == ACCOUNT_ID


class TestWriteReplicaCnf:
    def test_write_replica_cnf_for_tools_success(self, app, client, mock_envvars_api: Mocker):
        tool_path = app.config["TESTONLY_CORRECT_TOOL_PATH"]
        account_type = "tool"

        data = {
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": TOOL_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        for result in response_data["detail"]["results"].values():
            assert "ok" in result.lower()

        config_parser = ConfigParser()
        try:
            config_parser.read(tool_path)
        except ConfigParserError as err:
            raise AssertionError("The generated replica config file is not parseable") from err
        assert "client" in config_parser.sections()
        assert config_parser.get("client", "user") == USERNAME
        assert config_parser.get("client", "password") == PASSWORD

    def test_write_replica_cnf_for_tools_wrong_url_returns_404(self, app, client):
        account_type = "tool"

        data = {
            "mysql_username": "wrong-user",
            "password": PASSWORD,
            "account_id": WRONG_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/wrong-url", data=json.dumps(data), content_type="application/json"
        )
        assert response.status_code == 404

    def test_write_replica_cnf_for_tools_non_existing_parent_dir_returns_skip(
        self, client, app, mock_envvars_api
    ):
        wrong_tool_path = app.config["TESTONLY_WRONG_TOOL_PATH"]
        account_type = "tool"

        data = {
            "mysql_username": "wrong-user",
            "password": PASSWORD,
            "account_id": WRONG_TOOL_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)
        assert response.status_code == 200
        assert response_data["result"] == "skip"
        assert not os.path.exists(wrong_tool_path)

    def test_write_replica_cnf_for_paws_success(self, client, app):
        paw_path = app.config["TESTONLY_CORRECT_PAWS_PATH"]
        account_type = "paws"

        data = {
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        for result in response_data["detail"]["results"].values():
            assert "ok" in result.lower()

        config_parser = ConfigParser()
        try:
            config_parser.read(paw_path)
        except ConfigParserError as err:
            raise AssertionError("The generated replica config file is not parseable") from err
        assert "client" in config_parser.sections()
        assert config_parser.get("client", "user") == USERNAME
        assert config_parser.get("client", "password") == PASSWORD

    def test_write_replica_cnf_for_paws_wrong_url_returns_404(self, client):
        account_type = "paws"

        data = {
            "mysql_username": "wrong-user",
            "password": PASSWORD,
            "account_id": WRONG_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/wrong-url", data=json.dumps(data), content_type="application/json"
        )
        assert response.status_code == 404

    def test_write_replica_cnf_for_paws_non_existing_parent_dir_returns_skip(self, client, app):
        wrong_paw_path = app.config["TESTONLY_WRONG_PAWS_PATH"]
        account_type = "paws"

        data = {
            "mysql_username": "wrong-user",
            "password": PASSWORD,
            "account_id": WRONG_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)
        assert response.status_code == 200
        assert response_data["result"] == "skip"
        assert not os.path.exists(wrong_paw_path)

    def test_write_replica_cnf_for_users_success(self, client, app):
        other_path = app.config["TESTONLY_CORRECT_USER_PATH"]
        account_type = "user"

        data = {
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        for result in response_data["detail"]["results"].values():
            assert "ok" in result.lower()

        config_parser = ConfigParser()
        try:
            config_parser.read(other_path)
        except ConfigParserError as err:
            raise AssertionError("The generated replica config file is not parseable") from err
        assert "client" in config_parser.sections()
        assert config_parser.get("client", "user") == USERNAME
        assert config_parser.get("client", "password") == PASSWORD

    def test_write_replica_cnf_for_users_wrong_url_returns_404(self, client):
        account_type = "user"

        data = {
            "mysql_username": "wrong-user",
            "password": PASSWORD,
            "account_id": WRONG_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/wrong-url", data=json.dumps(data), content_type="application/json"
        )
        assert response.status_code == 404

    def test_write_replica_cnf_for_users_non_existing_parent_dir_returns_skip(self, client, app):
        wrong_other_path = app.config["TESTONLY_WRONG_USER_PATH"]
        account_type = "user"

        data = {
            "mysql_username": "wrong-user",
            "password": PASSWORD,
            "account_id": WRONG_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": False,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)
        assert response.status_code == 200
        assert response_data["result"] == "skip"
        assert not os.path.exists(wrong_other_path)

    def test_write_replica_cnf_dry_run(self, client, app):
        tool_path = app.config["TESTONLY_CORRECT_TOOL_PATH"]
        account_type = "tool"

        data = {
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": TOOL_ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
            "dry_run": True,
        }

        response = client.post(
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        for result in response_data["detail"]["results"].values():
            assert "ok" in result.lower()
        assert not os.path.exists(tool_path)


class TestReadReplicaCnf:
    def test_read_replica_cnf_success(self, client, create_replica_my_cnf, mock_envvars_api):
        data = {"account_id": TOOL_ACCOUNT_ID, "account_type": "tool", "dry_run": False}

        response = client.post(
            "/v1/read-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        assert response_data["detail"]["user"] == USERNAME
        assert response_data["detail"]["password"] == mysql_hash(PASSWORD)

    def test_read_replica_cnf_failure(self, client, create_replica_my_cnf, mock_envvars_api):
        data = {
            "account_id": "wrong-accound-id",
            "account_type": "tool",
            "dry_run": False,
        }

        response = client.post(
            "/v1/read-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 500
        assert response_data["result"] == "error"

    def test_read_replica_cnf_dry_run(self, client, mock_envvars_api):
        data = {"account_id": ACCOUNT_ID, "account_type": "tool", "dry_run": True}

        response = client.post(
            "/v1/read-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        assert response_data["detail"]["user"] == DRY_RUN_USERNAME
        assert response_data["detail"]["password"] == mysql_hash(DRY_RUN_PASSWORD)


class TestDeleteReplicaCnf:
    def test_delete_replica_cnf_success(self, client, create_replica_my_cnf, app, mock_envvars_api):
        tool_path = app.config["TESTONLY_CORRECT_TOOL_PATH"]
        data = {"account_id": TOOL_ACCOUNT_ID, "account_type": "tool", "dry_run": False}

        response = client.post(
            "/v1/delete-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        for result in response_data["detail"]["results"].values():
            assert "ok" in result.lower()
        assert not os.path.exists(tool_path)

    def test_delete_replica_cnf_failure(self, client, create_replica_my_cnf, app, mock_envvars_api):
        tool_path = app.config["TESTONLY_CORRECT_TOOL_PATH"]
        data = {
            "account_id": WRONG_TOOL_ACCOUNT_ID,
            "account_type": "tool",
            "dry_run": False,
        }

        response = client.post(
            "/v1/delete-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 500
        assert response_data["result"] == "error"
        assert "No such file or directory" in response_data["detail"]["reason"]
        assert os.path.exists(tool_path)

    def test_delete_replica_cnf_dry_run(self, client, create_replica_my_cnf, app, mock_envvars_api):
        tool_path = app.config["TESTONLY_CORRECT_TOOL_PATH"]
        data = {"account_id": TOOL_ACCOUNT_ID, "account_type": "tool", "dry_run": True}

        response = client.post(
            "/v1/delete-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        assert os.path.exists(tool_path)
