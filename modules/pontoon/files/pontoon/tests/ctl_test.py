#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import logging
import os
import shlex
import socket
import subprocess
import uuid
from pathlib import Path

import pytest
from click.testing import CliRunner
from pontoon.credentials import Credentials
from pontoon.ctl import ctl
from pontoon.ssh import KNOWN_HOSTS_PATH


# Clone puppet from current checkout once per session. Individual tests can then
# clone from this repo.  The goal is to leave the current git repo alone once
# tests have started. For example users are free to change the repo without
# affecting the tests or vice-versa.
@pytest.fixture(scope="session")
def session_clone(tmp_path_factory):
    # Pytest adds an auto-increment int to path_factory results. Therefore
    # append a dash to tmp_path_factory names to make it easier to read paths.
    # https://docs.pytest.org/en/stable/how-to/tmp_path.html#temporary-directory-location-and-retention
    dest_path = tmp_path_factory.mktemp("session-puppet-")

    p = assert_cmd_ok(
        "git rev-parse --show-toplevel",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    puppet_path = Path(p.stdout.decode("utf-8"))

    assert_cmd_ok(f"git clone {puppet_path} {dest_path}")

    return dest_path


@pytest.fixture(scope="class")
def puppet_clone(session_clone, class_uuid, tmp_path_factory):
    # Pytest adds an auto-increment int to path_factory results. Therefore
    # append a dash to tmp_path_factory names to make it easier to read paths.
    # https://docs.pytest.org/en/stable/how-to/tmp_path.html#temporary-directory-location-and-retention
    dest_path = tmp_path_factory.mktemp(f"puppet-{class_uuid}-")

    clone_cmd = f"git clone --reference {session_clone} {session_clone} {dest_path}"
    assert_cmd_ok(clone_cmd)

    name_cmd = f"git config user.name test-{class_uuid}"
    assert_cmd_ok(name_cmd, cwd=dest_path)

    email_cmd = f"git config user.email test-{class_uuid}@{socket.gethostname()}"
    assert_cmd_ok(email_cmd, cwd=dest_path)

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

    assert_cmd_ok("git add .", cwd=stack_path)
    assert_cmd_ok(f"git commit -m 'new stack {stack_name}'", cwd=stack_path)

    return stack_name, stack_path


@pytest.fixture(scope="class")
def bootstrap_stack(cli_runner: CliRunner, new_stack: str):
    name, _ = new_stack
    result = cli_runner.invoke(
        ctl,
        [
            "bootstrap-stack",
            "--stack",
            name,
            "--accept-ssh-key",
        ],
    )
    assert result.exit_code == 0, "Failed to bootstrap the stack"

    yield name, result

    # XXX cleanup


@pytest.fixture(scope="class")
def git_remote(cli_runner: CliRunner, new_stack: str, puppet_clone: str):
    """Set up the git remote pointing to new_stack"""

    # make 'git push' work unattended. depends on cli_runner to set os.environ
    # for KNOWN_HOSTS_PATH
    _ = cli_runner
    set_repo_known_hosts = (
        "git config --add --local "
        f"core.sshCommand 'ssh -o UserKnownHostsFile={KNOWN_HOSTS_PATH()}'"
    )
    assert_cmd_ok(set_repo_known_hosts, cwd=puppet_clone)

    name, _ = new_stack
    result = cli_runner.invoke(
        ctl,
        [
            "hosts-for-role",
            "--stack",
            name,
            "puppetserver::pontoon",
        ],
    )
    assert result.exit_code == 0, "Failed to find hosts for puppetserver::pontoon"

    server = result.output.strip()
    remote_url = f"ssh://{server}/~/puppet.git"
    remote = f"pontoon-{name}"

    assert_cmd_ok(f"git remote add {remote} {remote_url}", cwd=puppet_clone)

    yield remote

    # XXX teardown


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

    def test_bootstrap_stack(self, bootstrap_stack, caplog):
        """Test the bootstrap-stack command."""

        caplog.set_level(logging.INFO)

        name, result = bootstrap_stack

        result = self.runner.invoke(ctl, ["wait-puppet", "--stack", name])
        assert result.exit_code == 0, "wait-puppet did not finish successfully"

    def test_bootstrap_rolegroup(self, bootstrap_stack, caplog, git_remote, home):
        """Test the add-rolegroup command."""

        caplog.set_level(logging.INFO)

        name, _ = bootstrap_stack
        result = self.runner.invoke(
            ctl,
            [
                "add-rolegroup",
                "--stack",
                name,
                "bootstrap",
            ],
        )
        # XXX how to clean up after bootstrap / add roles ?
        assert result.exit_code == 0, "add-rolegroup did not finish successfully"

        cmds = [
            f"git add {home}",
            "git commit -m 'new rolegroup'",
            f"git push -f {git_remote} HEAD:production",
        ]
        for cmd in cmds:
            assert_cmd_ok(cmd, cwd=home)

        result = self.runner.invoke(
            ctl,
            [
                "create-hosts",
                "--stack",
                name,
                "--no-prompt",
            ],
        )
        assert result.exit_code == 0, "Failed to create hosts"

        result = self.runner.invoke(ctl, ["wait-puppet", "--stack", name])
        assert result.exit_code == 0, "wait-puppet did not finish successfully"


def assert_cmd_ok(cmd: str, *args, **kwargs) -> subprocess.CompletedProcess:
    p = subprocess.run(shlex.split(cmd), *args, **kwargs)
    assert p.returncode == 0, f"Failed to run {cmd!r}"

    return p
