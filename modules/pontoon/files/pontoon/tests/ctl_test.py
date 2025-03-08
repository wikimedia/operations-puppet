#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import os
import shlex
import subprocess
import uuid
import logging
from pathlib import Path

import pytest
from click.testing import CliRunner
from pontoon.ctl import ctl
from pontoon.credentials import Credentials


# Clone puppet from current checkout once per session. Individual tests can then
# clone from this repo.  The goal is to leave the current git repo alone once
# tests have started. For example users are free to change the repo without
# affecting the tests or vice-versa.
@pytest.fixture(scope="session")
def session_clone(tmp_path_factory):
    # Pytest adds an auto-increment int to path_factory results. Therefore
    # append a dash to tmp_path_factory names to make it easier to read paths.
    # https://docs.pytest.org/en/stable/how-to/tmp_path.html#temporary-directory-location-and-retention
    dest_path = tmp_path_factory.mktemp("session-puppet")

    p = subprocess.run(
        shlex.split("git rev-parse --show-toplevel"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert p.returncode == 0
    puppet_path = Path(p.stdout.decode("utf-8"))

    # XXX copy uncommitted files too
    p = subprocess.run(
        shlex.split(f"git clone --depth=1 file://{puppet_path} {dest_path}")
    )
    assert p.returncode == 0

    return dest_path


@pytest.fixture(scope="class")
def puppet_clone(session_clone, class_uuid, tmp_path_factory):
    dest_path = tmp_path_factory.mktemp(f"puppet-{class_uuid}-")

    # XXX copy uncommitted files too
    p = subprocess.run(
        shlex.split(f"git clone --depth=1 file://{session_clone} {dest_path}")
    )
    assert p.returncode == 0

    return dest_path


@pytest.fixture(scope="class")
def cli_runner(home: Path, config_home: Path):
    """Pytest fixture to provide a Click CLI runner for test cases."""
    os.environ["PONTOON_HOME"] = home.as_posix()
    os.environ["XDG_CONFIG_HOME"] = config_home.as_posix()
    return CliRunner()


@pytest.fixture(scope="class")
def home(puppet_clone):
    """Return a Path with Pontoon's home"""
    return puppet_clone / "modules" / "pontoon" / "files"


@pytest.fixture(scope="class")
def config_home(tmp_path_factory, class_uuid):
    """Return a Path to store Pontoon's config"""
    return tmp_path_factory.mktemp(f"config-{class_uuid}-")


@pytest.fixture(scope="class")
def class_uuid():
    return uuid.uuid4().hex[:4]


@pytest.fixture(scope="class")
def credentials(config_home: Path):
    creds_path = config_home / "pontoon" / "cloudvps.yaml"
    creds_path.parent.mkdir()

    id = os.getenv("PONTOON_CLOUD_ID")
    secret = os.getenv("PONTOON_CLOUD_SECRET")

    assert (
        id is not None and secret is not None
    ), "Could not find credentials in PONTOON_CLOUD_ID and PONTOON_CLOUD_SECRET"

    Credentials.write(creds_path.as_posix(), id, secret)

    yield id, secret

    # pytest temporary directory stays around after tests, make sure credentials do not
    creds_path.unlink()


@pytest.fixture(scope="class")
def new_stack(cli_runner: CliRunner, credentials: tuple, home: Path, class_uuid: str):
    """Create a new stack"""
    stack_name = f"test-{class_uuid}"
    stack_path = home.joinpath(stack_name)

    result = cli_runner.invoke(
        ctl,
        [
            "new-stack",
            "--stack",
            stack_name,
            "--host-prefix",
            stack_name,
        ],
    )
    assert result.exit_code == 0, f"Stack creation failed: {result.output}"

    p = subprocess.run(
        f"git add . && git commit -m 'new stack {stack_name}'",
        shell=True,
        cwd=stack_path,
    )
    assert p.returncode == 0

    return stack_name, stack_path


class TestGeneral:
    @pytest.fixture(autouse=True)
    def setup_fixture(self, cli_runner: CliRunner):
        self.runner = cli_runner

    def test_list_stacks(self):
        """Test the list-stacks command."""
        result = self.runner.invoke(ctl, ["list-stacks"])
        assert result.exit_code == 0
        assert "bootstrap" in result.output

    def test_ssh_config(self):
        """Test displaying SSH configuration."""
        result = self.runner.invoke(ctl, ["ssh-config"])
        assert result.exit_code == 0
        assert "Host" in result.output

    def test_env_directories(self, tmp_path_factory):
        home = Path(os.environ["PONTOON_HOME"])
        cfg = Path(os.environ["XDG_CONFIG_HOME"])
        base = tmp_path_factory.getbasetemp()
        assert base in home.parents
        assert base in cfg.parents

    def test_new_stack_cleanup(self, home):
        stack_name = f"test-{class_uuid}"
        stack_path = home.joinpath(stack_name)

        result = self.runner.invoke(
            ctl,
            [
                "new-stack",
                "--stack",
                stack_name,
                "--host-prefix",
                stack_name,
            ],
        )

        assert result.exit_code != 0
        assert not os.path.exists(stack_path)
        assert "Credentials not found" in result.stdout


@pytest.mark.integration
class TestBootstrap:
    @pytest.fixture(autouse=True)
    def setup_fixture(self, cli_runner: CliRunner):
        self.runner = cli_runner

    def test_new_stack(self, new_stack):
        """Test the new-stack command."""
        name, _ = new_stack
        result = self.runner.invoke(ctl, ["list-stacks"])
        assert result.exit_code == 0
        assert name in result.output

    def test_bootstrap_stack(self, new_stack, caplog):
        """Test the bootstrap-stack command."""

        caplog.set_level(logging.INFO)

        name, _ = new_stack
        # XXX need an unattended way to set up git remote
        result = self.runner.invoke(
            ctl,
            [
                "bootstrap-stack",
                "--stack",
                name,
                "--accept-ssh-key",
            ],
        )
        # XXX how to clean up after bootstrap / add roles ?
        assert result.exit_code == 0, "Bootstrap did not finish successfully"

        result = self.runner.invoke(ctl, ["wait-puppet", "--stack", name])
        assert result.exit_code == 0, "wait-puppet did not finish successfully"
