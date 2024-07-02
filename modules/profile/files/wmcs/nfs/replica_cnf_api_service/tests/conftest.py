#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

import configparser
import io
import os
import re
import subprocess
from pathlib import Path
from typing import Any
from unittest import mock

import pytest
import yaml
from replica_cnf_api_service.backends.envvars_backend import ToolforgeToolEnvvarsBackend
from replica_cnf_api_service.views import create_app
from requests_mock import Mocker

TOOL_PATH = Path("test_srv/tools/shared/tools/project")
PAWS_PATH = Path("test_srv/paws/project/paws/userhomes")
USER_PATH = Path("test_srv/tools/shared/tools/home")
ACCOUNT_ID = "test_tool"
TOOL_ACCOUNT_ID = "tools.test_tool"
WRONG_ACCOUNT_ID = "wrong_account_id"
WRONG_TOOL_ACCOUNT_ID = "tools.wrong_account_id"
USERNAME = "test_user"
PASSWORD = "test_password"
UID = os.getuid()
SCRIPTS_PATH = Path(__file__).resolve().parent.parent
TOOLS_PROJECT_PREFIX = "tools"
DUMMY_TOOLFORGE_API = "http://dummy.localhost"


def _get_dummy_kubeconfig() -> dict[str, Any]:
    return {
        "current-context": "dummycontext",
        "contexts": [
            {
                "name": "dummycontext",
                "context": {
                    "cluster": "dummycluster",
                    "user": "dummyuser",
                    "namespace": "dummynamespace",
                },
            }
        ],
        "clusters": [
            {
                "name": "dummycluster",
                "cluster": {
                    "server": "dummyserver",
                },
            }
        ],
        "users": [
            {
                "name": "dummyuser",
                "user": {
                    "token": "dummy token",
                },
            }
        ],
        "servers": [{"name": "dummyserver", "server": {}}],
    }


@pytest.fixture
def app(tmp_path: Path):
    # use pytest tmp_path so cleanup is automatically handled by pytest
    temp_tool_path = tmp_path / TOOL_PATH
    temp_paws_path = tmp_path / PAWS_PATH
    temp_user_path = tmp_path / USER_PATH

    dummy_kubeconfig_path: Path = tmp_path / "kubeconfig"
    dummy_kubeconfig_path.write_text(yaml.dump(_get_dummy_kubeconfig()))

    temp_replica_cnf_config_path = tmp_path / "replica_cnf_config.yaml"

    # in production this is automatically handled
    os.makedirs(temp_tool_path / TOOL_ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :])
    os.makedirs(temp_paws_path / ACCOUNT_ID)
    os.makedirs(temp_user_path / ACCOUNT_ID)

    correct_tool_path = (
        # flake8: noqa
        temp_tool_path
        / TOOL_ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :]
        / "replica.my.cnf"
    )
    wrong_tool_path = (
        temp_tool_path / WRONG_TOOL_ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :] / "replica.my.cnf"
    )
    correct_paws_path = temp_paws_path / ACCOUNT_ID / ".my.cnf"
    wrong_paws_path = temp_paws_path / WRONG_ACCOUNT_ID / ".my.cnf"
    correct_user_path = temp_user_path / ACCOUNT_ID / "replica.my.cnf"
    wrong_user_path = temp_user_path / WRONG_ACCOUNT_ID / "replica.my.cnf"

    # in production this is handled by puppet
    with open(temp_replica_cnf_config_path, "w+", encoding="utf8") as config:
        yaml.dump(
            {
                "TOOL_REPLICA_CNF_PATH": str(temp_tool_path),
                "USER_REPLICA_CNF_PATH": str(temp_user_path),
                "PAWS_REPLICA_CNF_PATH": str(temp_paws_path),
                "BACKENDS": {
                    "ToolforgeToolFileBackend": {
                        "ToolforgeToolBackendConfig": {
                            "replica_cnf_path": str(temp_tool_path),
                            "scripts_path": str(SCRIPTS_PATH),
                            "tools_project_prefix": TOOLS_PROJECT_PREFIX,
                            "use_sudo": False,
                        }
                    },
                    "ToolforgeUserFileBackend": {
                        "FileConfig": {
                            "replica_cnf_path": str(temp_user_path),
                            "scripts_path": str(SCRIPTS_PATH),
                            "use_sudo": False,
                        }
                    },
                    "PawsUserFileBackend": {
                        "FileConfig": {
                            "replica_cnf_path": str(temp_paws_path),
                            "scripts_path": str(SCRIPTS_PATH),
                            "use_sudo": False,
                        }
                    },
                    "ToolforgeToolEnvvarsBackend": {
                        "EnvvarsConfig": {
                            "kubeconfig_path_template": str(dummy_kubeconfig_path),
                            "toolforge_api_endpoint": DUMMY_TOOLFORGE_API,
                            "scripts_path": str(SCRIPTS_PATH),
                            "use_sudo": False,
                        }
                    },
                },
                "TESTONLY_CORRECT_TOOL_PATH": str(correct_tool_path),  # only for testing
                "TESTONLY_WRONG_TOOL_PATH": str(wrong_tool_path),  # only for testing
                "TESTONLY_CORRECT_PAWS_PATH": str(correct_paws_path),  # only for testing
                "TESTONLY_WRONG_PAWS_PATH": str(wrong_paws_path),  # only for testing
                "TESTONLY_CORRECT_USER_PATH": str(correct_user_path),  # only for testing
                "TESTONLY_WRONG_USER_PATH": str(wrong_user_path),  # only for testing
                "TESTONLY_SCRIPTS_PATH": str(SCRIPTS_PATH),  # only for testing
            },
            stream=config,
        )
    # this is only for test purpose
    subprocess.check_output(["chmod", "777", str(temp_replica_cnf_config_path)])

    os.environ["CONF_FILE"] = str(temp_replica_cnf_config_path)
    my_app = create_app()

    # We need to fake chattr to be able to run as regular user
    (tmp_path / "bin").mkdir(exist_ok=True)
    (tmp_path / "bin" / "chattr").write_text("""#!/bin/bash\nexit 0""")
    (tmp_path / "bin" / "chattr").chmod(0x0555)
    with mock.patch.dict(os.environ, {"PATH": f"{tmp_path / 'bin'}:{os.environ['PATH']}"}):
        with my_app.app_context():
            yield my_app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture()
def create_replica_my_cnf(app):
    """Create replica.my.cnf file before test run"""
    # Setup

    relative_path = Path(TOOL_ACCOUNT_ID[len(TOOLS_PROJECT_PREFIX) + 1 :]) / "replica.my.cnf"

    replica_config = configparser.ConfigParser()

    replica_config["client"] = {"user": USERNAME, "password": PASSWORD}
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    # don't catch exception. this allows us to know that the test failure is from this setup
    subprocess.check_output(
        [
            str(Path(app.config["TESTONLY_SCRIPTS_PATH"]) / "write_replica_cnf.sh"),
            str(UID),
            str(relative_path),
            replica_buffer.getvalue().encode("utf-8"),
            "tool",
        ]
    )


@pytest.fixture
def mock_envvars_api(requests_mock: Mocker):
    for var in ToolforgeToolEnvvarsBackend.USER_ENVVARS:
        name_envvar = {
            "name": var,
            "value": USERNAME,
        }
        wrapped_response = {
            "envvar": name_envvar,
            "messages": {
                "info": [],
                "warning": [],
                "error": [],
            },
        }
        user_url_match = re.compile(f"{DUMMY_TOOLFORGE_API}/envvars/v1/tool/[^/]+/envvar/{var}")

        for method in ("GET", "POST", "DELETE"):
            requests_mock.register_uri(method, user_url_match, json=wrapped_response)

    for var in ToolforgeToolEnvvarsBackend.PASSWORD_ENVVARS:
        pass_envvar = {
            "name": var,
            "value": PASSWORD,
        }
        pass_url_match = re.compile(f"{DUMMY_TOOLFORGE_API}/envvars/v1/tool/[^/]+/envvar/{var}")
        wrapped_response = {
            "envvar": pass_envvar,
            "messages": {
                "info": [],
                "warning": [],
                "error": [],
            },
        }

        for method in ("GET", "POST", "DELETE"):
            requests_mock.register_uri(method, pass_url_match, json=wrapped_response)

    return requests_mock
