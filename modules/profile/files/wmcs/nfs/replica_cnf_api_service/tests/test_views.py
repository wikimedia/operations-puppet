#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import os

from flask import current_app

from replica_cnf_api_service.views import get_replica_path, mysql_hash

from .conftest import ACCOUNT_ID, OTHERS_PATH, PASSWORD, PAWS_PATH, TOOLS_PATH, UID, USERNAME


def test_mysql_hash():
    expected_hash = "*4414e26eded6d661b5386813ebba95065dbc4728"
    password = "test_password"
    assert mysql_hash(password) == expected_hash


def test_get_replica_path(app):
    with app.app_context():
        TOOLS_REPLICA_CNF_PATH = current_app.config["TOOLS_REPLICA_CNF_PATH"]
        PAWS_REPLICA_CNF_PATH = current_app.config["PAWS_REPLICA_CNF_PATH"]
        OTHERS_REPLICA_CNF_PATH = current_app.config["OTHERS_REPLICA_CNF_PATH"]

        path = get_replica_path("tool", ACCOUNT_ID)
        assert path == os.path.join(TOOLS_REPLICA_CNF_PATH, ACCOUNT_ID, "replica.my.cnf")

        path = get_replica_path("paws", ACCOUNT_ID)
        assert path == os.path.join(PAWS_REPLICA_CNF_PATH, ACCOUNT_ID, ".my.cnf")

        path = get_replica_path(None, ACCOUNT_ID)
        assert path == os.path.join(OTHERS_REPLICA_CNF_PATH, ACCOUNT_ID, "replica.my.cnf")


def test_fetch_replica_path_for_tools(client):

    account_type = "tool"

    expected_path = TOOLS_PATH.joinpath(ACCOUNT_ID, "replica.my.cnf")

    response = client.post(
        "/v1/fetch-replica-path", json={"account_id": ACCOUNT_ID, "account_type": account_type}
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["detail"]["replica_path"] == str(expected_path)


def test_fetch_replica_path_for_paws(client):

    account_type = "paws"

    expected_path = PAWS_PATH.joinpath(ACCOUNT_ID, ".my.cnf")

    response = client.post(
        "/v1/fetch-replica-path", json={"account_id": ACCOUNT_ID, "account_type": account_type}
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["detail"]["replica_path"] == str(expected_path)


def test_fetch_replica_path_for_others(client):

    account_type = "others"

    expected_path = OTHERS_PATH.joinpath(ACCOUNT_ID, "replica.my.cnf")

    response = client.post(
        "/v1/fetch-replica-path", json={"account_id": ACCOUNT_ID, "account_type": account_type}
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["detail"]["replica_path"] == str(expected_path)


def test_write_replica_cnf_for_tools(client):

    account_type = "tool"

    expected_path = TOOLS_PATH.joinpath(ACCOUNT_ID, "replica.my.cnf")

    response = client.post(
        "/v1/write-replica-cnf",
        json={
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
        },
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["detail"]["replica_path"] == str(expected_path)

    with open(response.json["detail"]["replica_path"], "r") as file:
        file = file.readlines()
        assert file[0].strip() == "[client]"
        assert file[1].strip() == "user = " + USERNAME
        assert file[2].strip() == "password = " + PASSWORD


def test_write_replica_cnf_for_paws(client):

    account_type = "paws"

    expected_path = PAWS_PATH.joinpath(ACCOUNT_ID, ".my.cnf")

    response = client.post(
        "/v1/write-replica-cnf",
        json={
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
        },
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["detail"]["replica_path"] == str(expected_path)

    with open(response.json["detail"]["replica_path"], "r") as file:
        file = file.readlines()
        assert file[0].strip() == "[client]"
        assert file[1].strip() == "user = " + USERNAME
        assert file[2].strip() == "password = " + PASSWORD


def test_write_replica_cnf_for_others(client):

    account_type = "others"

    expected_path = OTHERS_PATH.joinpath(ACCOUNT_ID, "replica.my.cnf")

    response = client.post(
        "/v1/write-replica-cnf",
        json={
            "mysql_username": USERNAME,
            "password": PASSWORD,
            "account_id": ACCOUNT_ID,
            "account_type": account_type,
            "uid": UID,
        },
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"
    assert response.json["detail"]["replica_path"] == str(expected_path)

    with open(response.json["detail"]["replica_path"], "r") as file:
        file = file.readlines()
        assert file[0].strip() == "[client]"
        assert file[1].strip() == "user = " + USERNAME
        assert file[2].strip() == "password = " + PASSWORD


def test_read_replica_cnf(client, create_replica_my_cnf):

    response = client.post(
        "/v1/read-replica-cnf", json={"account_id": ACCOUNT_ID, "account_type": "tool"}
    )

    assert response.status_code == 200
    assert response.json["result"] == "ok"

    res_json = response.json

    assert res_json["detail"]["user"] == USERNAME
    assert res_json["detail"]["password"] == mysql_hash(PASSWORD)
