#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import configparser
import io
import os
import shutil
import subprocess
from pathlib import Path
from uuid import uuid4

import pytest

from replica_cnf_api_service.views import create_app

BASE_PATH = Path("/tmp").joinpath(uuid4().hex)
TOOLS_PATH = BASE_PATH.joinpath("test_srv/tools/shared/tools/project/")
PAWS_PATH = BASE_PATH.joinpath("test_srv/misc/shared/paws/project/paws/userhomes/")
OTHERS_PATH = BASE_PATH.joinpath("test_srv/tools/shared/tools/home/")
ACCOUNT_ID = "test_tool"
USERNAME = "test_user"
PASSWORD = "test_password"
UID = os.getuid()


def remove_base_if_path_exists(path):
    if os.path.exists(path):
        subprocess.run(["/usr/bin/chattr", "-i", path])
        shutil.rmtree(BASE_PATH, ignore_errors=True)


@pytest.fixture
def app():
    return create_app(
        {
            "TESTING": True,
            "TOOLS_REPLICA_CNF_PATH": str(TOOLS_PATH),
            "PAWS_REPLICA_CNF_PATH": str(PAWS_PATH),
            "OTHERS_REPLICA_CNF_PATH": str(OTHERS_PATH),
        }
    )


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def runner(app):
    return app.test_cli_runner()


@pytest.fixture(autouse=True)
def create_and_delete_necessary_dirs():
    """Fixture to execute asserts before and after a test is run"""
    # Setup
    tool_file_path = TOOLS_PATH.joinpath(ACCOUNT_ID)
    paws_file_path = PAWS_PATH.joinpath(ACCOUNT_ID)
    others_file_path = OTHERS_PATH.joinpath(ACCOUNT_ID)

    os.makedirs(tool_file_path, exist_ok=True)
    os.makedirs(paws_file_path, exist_ok=True)
    os.makedirs(others_file_path, exist_ok=True)

    yield

    # Teardown
    remove_base_if_path_exists(tool_file_path.joinpath("replica.my.cnf"))
    remove_base_if_path_exists(paws_file_path.joinpath(".my.cnf"))
    remove_base_if_path_exists(others_file_path.joinpath("replica.my.cnf"))


@pytest.fixture()
def create_replica_my_cnf(create_and_delete_necessary_dirs):
    """Create replica.my.cnf file before test run"""
    # Setup

    replica_path = TOOLS_PATH.joinpath(ACCOUNT_ID, "replica.my.cnf")

    replica_config = configparser.ConfigParser()

    replica_config["client"] = {"user": USERNAME, "password": PASSWORD}
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    c_file = os.open(replica_path, os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW)

    try:
        os.write(c_file, replica_buffer.getvalue().encode("utf-8"))
        os.fchown(c_file, UID, UID)
        os.fchmod(c_file, 0o400)

    # don't catch exception. this allows us to know that the test failure is from this setup
    finally:
        os.close(c_file)
