#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import json
import os
from configparser import ConfigParser
from configparser import Error as ConfigParserError
from pathlib import Path

import pytest
from flask import current_app
from replica_cnf_api_service.views import (
    DRY_RUN_PASSWORD,
    DRY_RUN_USERNAME,
    get_command_array,
    get_relative_path,
    get_replica_path,
    mysql_hash,
)

from .conftest import ACCOUNT_ID, PASSWORD, TOOLS_PROJECT_PREFIX, UID, USERNAME, WRONG_ACCOUNT_ID


def test_mysql_hash():
    expected_hash = "*4414e26eded6d661b5386813ebba95065dbc4728"
    password = "test_password"
    assert mysql_hash(password) == expected_hash


@pytest.mark.parametrize(
    "script", ["write_replica_cnf.sh", "read_replica_cnf.sh", "delete_replica_cnf.sh"]
)
def test_get_command_array(app, script):
    script_path = str(Path(current_app.config["SCRIPTS_PATH"]) / script)

    command_array = get_command_array(script=script)
    assert type(command_array) == list
    assert len(command_array) == 1
    assert command_array[0] == script_path

    current_app.config["USE_SUDO"] = True
    command_array = get_command_array(script=script)
    assert type(command_array) == list
    assert len(command_array) == 2
    assert command_array[0] == "sudo"
    assert command_array[1] == script_path


@pytest.mark.parametrize(
    "account_type, relative_path, get_expected_path",
    [
        [
            "tool",
            # flake8: noqa
            str(Path(ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :]) / "replica.my.cnf"),
            lambda _app: _app.config["CORRECT_TOOL_PATH"],
        ],
        [
            "paws",
            str(Path(ACCOUNT_ID) / ".my.cnf"),
            lambda _app: _app.config["CORRECT_PAWS_PATH"],
        ],
        [
            "user",
            str(Path(ACCOUNT_ID) / "replica.my.cnf"),
            lambda _app: _app.config["CORRECT_USER_PATH"],
        ],
    ],
)
def test_get_replica_path(app, account_type, relative_path, get_expected_path):
    assert get_expected_path(current_app) == get_replica_path(account_type, relative_path)


@pytest.mark.parametrize(
    "account_type, expected_path",
    [
        # flake8: noqa
        [
            "tool",
            str(Path(ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :]) / "replica.my.cnf"),
        ],
        ["paws", str(Path(ACCOUNT_ID) / ".my.cnf")],
        ["user", str(Path(ACCOUNT_ID) / "replica.my.cnf")],
    ],
)
def test_get_relative_path(app, account_type, expected_path):
    assert expected_path == get_relative_path(account_type, ACCOUNT_ID)


def test_fetch_paws_uids_success(client):
    response = client.get("/v1/paws-uids")
    response_data = json.loads(response.data)
    assert response.status_code == 200
    assert response_data["result"] == "ok"
    assert type(response_data["detail"]["paws_uids"]) == list
    assert response_data["detail"]["paws_uids"][0] == ACCOUNT_ID


class TestWriteReplicaCnf:
    def test_write_replica_cnf_for_tools_success(self, client):
        tool_path = current_app.config["CORRECT_TOOL_PATH"]
        account_type = "tool"

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
        assert response_data["detail"]["replica_path"] == tool_path

        config_parser = ConfigParser()
        try:
            config_parser.read(response_data["detail"]["replica_path"])
        except ConfigParserError as err:
            raise AssertionError("The generated replica config file is not parseable") from err
        assert "client" in config_parser.sections()
        assert config_parser.get("client", "user") == USERNAME
        assert config_parser.get("client", "password") == PASSWORD

    def test_write_replica_cnf_for_tools_wrong_url_returns_404(self, client):
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

    def test_write_replica_cnf_for_tools_non_existing_parent_dir_returns_skip(self, client):
        wrong_tool_path = current_app.config["WRONG_TOOL_PATH"]
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
            "/v1/write-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)
        assert response.status_code == 200
        assert response_data["result"] == "skip"
        assert response_data["detail"]["replica_path"] == wrong_tool_path
        assert not os.path.exists(wrong_tool_path)

    def test_write_replica_cnf_for_paws_success(self, client):
        paw_path = current_app.config["CORRECT_PAWS_PATH"]
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
        assert response_data["detail"]["replica_path"] == paw_path

        config_parser = ConfigParser()
        try:
            config_parser.read(response_data["detail"]["replica_path"])
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

    def test_write_replica_cnf_for_paws_non_existing_parent_dir_returns_500(self, client):
        wrong_paw_path = current_app.config["WRONG_PAWS_PATH"]
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
        assert response.status_code == 500
        assert response_data["result"] == "error"
        assert "No such file or directory" in response_data["detail"]["reason"]
        assert not os.path.exists(wrong_paw_path)

    def test_write_replica_cnf_for_users_success(self, client):
        other_path = current_app.config["CORRECT_USER_PATH"]
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
        assert response_data["detail"]["replica_path"] == other_path

        config_parser = ConfigParser()
        try:
            config_parser.read(response_data["detail"]["replica_path"])
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

    def test_write_replica_cnf_for_users_non_existing_parent_dir_returns_skip(self, client):
        wrong_other_path = current_app.config["WRONG_USER_PATH"]
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
        assert response_data["detail"]["replica_path"] == wrong_other_path
        assert not os.path.exists(wrong_other_path)

    def test_write_replica_cnf_dry_run(self, client):
        tool_path = current_app.config["CORRECT_TOOL_PATH"]
        account_type = "tool"

        data = {
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": ACCOUNT_ID,
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
        assert response_data["detail"]["replica_path"] == tool_path
        assert not os.path.exists(tool_path)


class TestReadReplicaCnf:
    def test_read_replica_cnf_success(self, client, create_replica_my_cnf):
        data = {"account_id": ACCOUNT_ID, "account_type": "tool", "dry_run": False}

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

    def test_read_replica_cnf_failure(self, client, create_replica_my_cnf):
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

    def test_read_replica_cnf_dry_run(self, client):
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
    def test_delete_replica_cnf_success(self, client, create_replica_my_cnf):
        tool_path = current_app.config["CORRECT_TOOL_PATH"]
        data = {"account_id": ACCOUNT_ID, "account_type": "tool", "dry_run": False}

        response = client.post(
            "/v1/delete-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        assert response_data["detail"]["replica_path"] == tool_path
        assert not os.path.exists(tool_path)

    def test_delete_replica_cnf_failure(self, client, create_replica_my_cnf):
        tool_path = current_app.config["CORRECT_TOOL_PATH"]
        data = {
            "account_id": WRONG_ACCOUNT_ID,
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

    def test_delete_replica_cnf_dry_run(self, client, create_replica_my_cnf):
        tool_path = current_app.config["CORRECT_TOOL_PATH"]
        data = {"account_id": ACCOUNT_ID, "account_type": "tool", "dry_run": True}

        response = client.post(
            "/v1/delete-replica-cnf",
            data=json.dumps(data),
            content_type="application/json",
        )
        response_data = json.loads(response.data)

        assert response.status_code == 200
        assert response_data["result"] == "ok"
        assert response_data["detail"]["replica_path"] == tool_path
        assert os.path.exists(tool_path)
