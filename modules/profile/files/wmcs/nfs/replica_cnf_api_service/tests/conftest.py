#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import configparser
import io
import os
import subprocess
from pathlib import Path

import pytest
from flask import current_app
from replica_cnf_api_service.views import create_app

TOOL_PATH = Path("test_srv/tools/shared/tools/project")
PAWS_PATH = Path("test_srv/paws/project/paws/userhomes")
USER_PATH = Path("test_srv/tools/shared/tools/home")
ACCOUNT_ID = "test_tool"
WRONG_ACCOUNT_ID = "wrong_account_id"
USERNAME = "test_user"
PASSWORD = "test_password"
UID = os.getuid()
PREV_SCRIPTS_PATH = Path(__file__).resolve().parent.parent
TOOLS_PROJECT_PREFIX = "tools"


@pytest.fixture
def app(tmp_path):
    # use pytest tmp_path so cleanup is automatically handled by pytest
    temp_tool_path = tmp_path / TOOL_PATH
    temp_paws_path = tmp_path / PAWS_PATH
    temp_user_path = tmp_path / USER_PATH

    temp_replica_cnf_config_path = tmp_path / "replica_cnf_config.yaml"

    # in production this is automatically handled
    # flake8: noqa
    os.makedirs(temp_tool_path / ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :])
    os.makedirs(temp_paws_path / ACCOUNT_ID)
    os.makedirs(temp_user_path / ACCOUNT_ID)

    correct_tool_path = (
        # flake8: noqa
        temp_tool_path
        / ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :]
        / "replica.my.cnf"
    )
    wrong_tool_path = (
        # flake8: noqa
        temp_tool_path
        / WRONG_ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :]
        / "replica.my.cnf"
    )
    correct_paws_path = temp_paws_path / ACCOUNT_ID / ".my.cnf"
    wrong_paws_path = temp_paws_path / WRONG_ACCOUNT_ID / ".my.cnf"
    correct_user_path = temp_user_path / ACCOUNT_ID / "replica.my.cnf"
    wrong_user_path = temp_user_path / WRONG_ACCOUNT_ID / "replica.my.cnf"

    # in production this is handled by puppet
    with open(temp_replica_cnf_config_path, "w+", encoding="utf8") as config:
        config.write(
            "\n".join(
                [
                    "USE_SUDO: false",
                    "SCRIPTS_PATH: {0}".format(str(tmp_path)),
                    "TOOLS_PROJECT_PREFIX: {}".format(TOOLS_PROJECT_PREFIX),
                    "TOOL_REPLICA_CNF_PATH: {0}".format(str(temp_tool_path)),
                    # mix quoted and unquoted strings for yaml format testing
                    'PAWS_REPLICA_CNF_PATH: "{0}"'.format(str(temp_paws_path)),
                    "USER_REPLICA_CNF_PATH: {0}".format(str(temp_user_path)),
                ]
            )
        )
    # this is only for test purpose
    subprocess.check_output(["chmod", "777", str(temp_replica_cnf_config_path)])

    scripts = ["write_replica_cnf.sh", "read_replica_cnf.sh", "delete_replica_cnf.sh"]

    for script in scripts:
        # copy the scripts to pytest tmp directory before editing them
        with open(PREV_SCRIPTS_PATH / script, encoding="utf8") as file1:
            with open(tmp_path / script, "w+", encoding="utf8") as file2:
                file2.write(file1.read())

        # this is only for test purpose
        subprocess.check_output(["chmod", "777", str(tmp_path / script)])

        # replace path /etc/replica_cnf_config.yaml in the scripts inside
        # pytest tmp_path with the correct values for test purpose
        subprocess.check_output(
            [
                "sed",
                "-i",
                "s|/etc/replica_cnf_config.yaml|{0}|".format(str(temp_replica_cnf_config_path)),
                str(tmp_path / script),
            ]
        )

        if script == scripts[0]:
            # since we don't have access to 'sudo' in tests, don't run chattr
            subprocess.check_output(["sed", "-i", "s/chattr +i.*//", str(tmp_path / script)])

    my_app = create_app(
        {
            "TESTING": True,
            "USE_SUDO": False,
            "SCRIPTS_PATH": str(tmp_path),
            "TOOLS_PROJECT_PREFIX": TOOLS_PROJECT_PREFIX,
            "TOOL_REPLICA_CNF_PATH": str(temp_tool_path),
            "PAWS_REPLICA_CNF_PATH": str(temp_paws_path),
            "USER_REPLICA_CNF_PATH": str(temp_user_path),
            "CORRECT_TOOL_PATH": str(correct_tool_path),  # only for testing
            "WRONG_TOOL_PATH": str(wrong_tool_path),  # only for testing
            "CORRECT_PAWS_PATH": str(correct_paws_path),  # only for testing
            "WRONG_PAWS_PATH": str(wrong_paws_path),  # only for testing
            "CORRECT_USER_PATH": str(correct_user_path),  # only for testing
            "WRONG_USER_PATH": str(wrong_user_path),  # only for testing
        }
    )

    with my_app.app_context():
        yield my_app


@pytest.fixture
def client(app):
    return current_app.test_client()


@pytest.fixture()
def create_replica_my_cnf(app):
    """Create replica.my.cnf file before test run"""
    # Setup

    relative_path = (
        # flake8: noqa
        Path(ACCOUNT_ID[len(app.config.get("TOOLS_PROJECT_PREFIX")) + 1 :])
        / "replica.my.cnf"
    )

    replica_config = configparser.ConfigParser()

    replica_config["client"] = {"user": USERNAME, "password": PASSWORD}
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    # don't catch exception. this allows us to know that the test failure is from this setup
    subprocess.check_output(
        [
            str(Path(current_app.config["SCRIPTS_PATH"]) / "write_replica_cnf.sh"),
            str(UID),
            str(relative_path),
            replica_buffer.getvalue().encode("utf-8"),
            "tool",
        ]
    )
