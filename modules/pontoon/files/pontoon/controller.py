#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0


import json
import logging
import os
import subprocess
from dataclasses import dataclass
from typing import Optional

from pontoon import Pontoon
from pontoon.cloudvps import CloudVPS
from pontoon.enroll import Enroller
from pontoon.rolegroups import RoleGroups
from pontoon.util import SSH_CONNECT_TIMEOUT_SECONDS, ssh_bash, wait_subprocesses
from ruamel.yaml import YAML

log = logging.getLogger()
WAIT_PUPPET_TIMEOUT_MINUTES = 5


@dataclass
class WaitPuppetResult:
    fqdn: str
    status: str
    stdout: str
    stderr: str


class Controller(object):
    def __init__(self, pontoon: Pontoon, cloud: CloudVPS):
        self._rolegroups = None
        self.yaml = YAML()
        self.pontoon = pontoon
        self.cloud = cloud

    @classmethod
    def config_dir(cls) -> str:
        """Where to store Pontoon configuration."""
        base_config_dir = os.environ.get("XDG_CONFIG_HOME", "~/.config")
        config_dir = os.path.join(base_config_dir, "pontoon")
        return os.path.expanduser(config_dir)

    @property
    def server(self) -> Optional[str]:
        return self.pontoon.server_fqdn

    @property
    def rolegroups(self) -> RoleGroups:
        if self._rolegroups is not None:
            return self._rolegroups
        self._rolegroups = self._load_rolegroups()
        return self._rolegroups

    def _load_rolegroups(self) -> RoleGroups:
        groupmap = {}

        groupfile = os.path.join(self.pontoon.base_path, "rolegroups.yaml")
        with open(groupfile, encoding="utf-8") as f:
            groupmap = self.yaml.load(f)

        stack_groupfile = os.path.join(self.pontoon.stack_path, "rolegroups.yaml")
        if os.path.exists(stack_groupfile):
            with open(stack_groupfile, encoding="utf-8") as f:
                stack_groupmap = self.yaml.load(f)
                groupmap.update(stack_groupmap)

        return RoleGroups(groupmap)

    def add_rolegroup(self, name: str) -> bool:
        """Add a role group to the Pontoon stack.

        Args:
            name (str): The role group to add
        """
        group = self.rolegroups.get_group(name)
        if not group.roles:
            log.error("Group %s not found", name)
            return False

        for role in group.roles:
            if role in self.pontoon.rolemap:
                log.debug("Role %s already exists, skipping", role)
                continue
            hostname = self._hostname_for_role(role)
            fqdn = self.cloud.fqdn(hostname)
            self.pontoon.add_host_to_role(fqdn, role)
        self.pontoon.save()

        for setting in group.settings:
            destfile = f"{self.pontoon.stack_path}/hiera/{setting}.yaml"
            if os.path.lexists(destfile):
                log.debug("Setting %s already exists, skipping", setting)
                continue
            os.symlink(f"../../settings/{setting}.yaml", destfile)
            if not os.path.exists(destfile):
                log.error(
                    f"Unable to find source setting file for {setting}. "
                    f"Check {self.pontoon.stack_path}/hiera"
                )
                continue

        return True

    def wait_puppet(self, role: Optional[str]) -> tuple[bool, list[WaitPuppetResult]]:
        """Wait for puppet runs to finish on hosts.

        Args:
            role (str): The role to wait for, or None for all roles

        Returns:
            bool: True if all hosts succeeded, False otherwise
            List[WaitPuppetResult]: List of results for each host
        """

        def commands_for_hosts(hosts):
            """Generator yielding (command, subprocess) tuples."""
            for host in hosts:
                proc = subprocess.Popen(
                    [
                        "ssh",
                        "-o",
                        "BatchMode=yes",
                        "-o",
                        "ControlPersist=5",
                        "-o",
                        "RequestTty=force",  # make sure remote processes get SIGHUP on exit
                        "-o",
                        f"ConnectTimeout={SSH_CONNECT_TIMEOUT_SECONDS}",
                        host,
                        "sudo pontoon-wait-puppet",
                    ],
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                yield host, proc

        candidates = self.pontoon.host_map().keys()

        if role is not None:
            try:
                candidates = self.pontoon.hosts_for_role(role)
            except ValueError:
                log.error(f"Role {role!r} not found")
                return False, [WaitPuppetResult("", "", "", "")]

        log.info(f"Waiting for puppet to converge on {len(candidates)} hosts")

        results = wait_subprocesses(
            commands_for_hosts(candidates), timeout=60 * WAIT_PUPPET_TIMEOUT_MINUTES
        )

        ret = []

        ok = True
        for fqdn, result in results.items():
            returncode, stdout, stderr = result
            status = "success" if returncode == 0 else "error"
            ret.append(WaitPuppetResult(fqdn, status, stdout, stderr))
            if returncode != 0:
                ok = False

        return ok, ret

    def _hostname_for_role(self, role: str, id: str = "01") -> str:
        host_prefix = self.pontoon.get_config_value("host_prefix")
        if not host_prefix:
            host_prefix = self.default_host_prefix
        role_hostname = self.cloud.specs_for_role(role).hostname
        return f"{host_prefix}-{role_hostname}-{id}"

    @property
    def default_host_prefix(self) -> str:
        stack_name = self.pontoon.name
        if "-" not in stack_name:
            return stack_name

        # Pick a short(er) name as host prefix, skip first letter for better readability
        novowels = stack_name[1:].translate({ord(i): None for i in "aeiouAEIOU"})
        return stack_name[0] + novowels

    def new_stack(self, host_prefix: str) -> bool:
        self.pontoon.set_config_value("host_prefix", host_prefix)

        hostname = self._hostname_for_role("puppetserver::pontoon")
        fqdn = self.cloud.fqdn(hostname)
        if fqdn in self.cloud.fqdns:
            log.error(
                f"The server {fqdn} already exists in project {self.cloud.project!r}"
            )
            return False

        self.pontoon.add_host_to_role(fqdn, "puppetserver::pontoon")
        self.pontoon.save()
        return True

    def bootstrap_stack(self, local_rev: str) -> bool:
        # XXX run init_ssh_access after host is created?
        if not self.server:
            log.error(f"Server not found for {self.pontoon.name}, does the stack exist?")
            return False

        self.cloud.create_hosts(hosts=set([self.server]))
        log.info(f"Bootstrapping {self.server} for stack {self.pontoon.name}")
        bootstrap_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "bootstrap.sh"
        )
        status = subprocess.call(
            [
                "scp",
                "-q",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                bootstrap_path,
                self.server + ":",
            ]
        )
        if status != 0:
            log.error("Error copying bootstrap.sh")
            return False

        proc = ssh_bash(
            self.server,
            f"sudo ./bootstrap.sh --check {self.pontoon.name}",
        )

        if proc.returncode == 2:
            log.info("Bootstrap already completed.")
            return True

        # Users can provide their code/data in $HOME/bootstrap
        send_local_checkout = f"""
        cd $(git rev-parse --show-toplevel) && \
            git archive --format tgz {local_rev} | \
                ssh -o StrictHostKeyChecking=no {self.server} \
                    'install -d bootstrap/puppet && tar zxf - -C bootstrap/puppet'
        """
        log.info(f"Sending local checkout of {local_rev} to {self.server}")
        subprocess.call(["bash", "-c", send_local_checkout])

        log.info(f"Bootstrapping {self.server}")
        proc = ssh_bash(self.server, f"sudo ./bootstrap.sh {self.pontoon.name}")

        if proc.returncode != 0:
            log.error(f"Error running bootstrap.sh on {self.server}")
            return False

        # Kick off the first agent run with itself as the server
        proc = ssh_bash(
            self.server,
            "sudo puppet agent --onetime --no-daemonize --no-splay --verbose",
        )

        return True

    def enroll_hosts(self, role: Optional[str], force: bool = False) -> bool:
        candidates = self.pontoon.host_map().keys()

        if role is not None:
            try:
                candidates = self.pontoon.hosts_for_role(role)
            except ValueError:
                log.error(f"Role {role!r} not found")
                return False

        if force:
            enrolled_hosts = []
        else:
            log.info("Searching for hosts to enroll")
            proc = ssh_bash(
                self.server,
                "sudo puppetserver ca list --format json --all",
                capture_output=True,
                text=True,
            )
            try:
                ca_list = json.loads(proc.stdout)
            except json.decoder.JSONDecodeError:
                log.error(f"Unable to get list of enrolled hosts from {proc.stdout!r}")
                return False
            enrolled_hosts = [x["name"] for x in ca_list["signed"]]

        to_enroll = set(candidates) - set(enrolled_hosts)
        if not to_enroll:
            log.info("No hosts to enroll")
            return False

        # Abort if the hosts are not known yet to the server
        proc = ssh_bash(
            self.server,
            "pontoon-enc --list-hosts",
            capture_output=True,
            text=True,
        )
        enrollable_hosts = proc.stdout.split("\n")
        missing_on_server = set(to_enroll) - set(enrollable_hosts)
        if missing_on_server:
            log.error(
                "The following hosts need enrolling and could not be found ."
                f"on Pontoon server: {missing_on_server}"
            )
            log.error("You might need to push an updated rolemap.yaml")
            return False

        e = Enroller(self.pontoon)
        ok = True
        # XXX enroll concurrently
        for host in to_enroll:
            if not e.enroll(host, force=force):
                ok = False
                # Normally pontoon-wait-puppet is deployed by Puppet, though
                # during enrollment the first puppet run can fail too.
                # The script can be used to wait for puppet runs to succeed.
                self._install_wait_puppet(host)

        return ok

    def _install_wait_puppet(self, host: str) -> bool:
        wait_puppet_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "pontoon_wait_puppet.py"
        )
        status = subprocess.call(
            [
                "scp",
                "-q",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                wait_puppet_path,
                f"{host}:/tmp/pontoon_wait_puppet.py",
            ]
        )

        if status != 0:
            log.error(f"Error copying {wait_puppet_path}")
            return False

        p = ssh_bash(
            host,
            "sudo install -m755 /tmp/pontoon_wait_puppet.py /usr/local/bin/pontoon-wait-puppet",
        )
        if p.returncode != 0:
            log.error("Failed to install pontoon-wait-puppet")
            return False

        return True

    def init_ssh_access(self) -> bool:
        """Add the server SSH host key to the user's known_hosts.

        Needed to be able to anchor trust to the server and be able
        to run 'ssh-keyscan' across stacks.
        """
        log.info(
            f"Logging into {self.server} for the first time. Please verify and accept the host key."
        )
        p = subprocess.run(
            [
                "ssh",
                "-o",
                "HashKnownHosts=no",
                f"{self.server}",
                "true",
            ]
        )
        return p.returncode == 0

    def setup_remote_repositories(self) -> bool:
        """Set up the Pontoon stack server to act as a git remote for the user."""

        if not self.server:
            log.error(
                f"Unable to find puppetserver::pontoon host for stack {self.pontoon.name}"
            )
            return False

        repos = {
            "puppet.git": (
                "https://gerrit.wikimedia.org/r/operations/puppet",
                "production",
                "/srv/git/operations/puppet",
            ),
            "private.git": (
                "https://gerrit.wikimedia.org/r/labs/private",
                "master",
                "/srv/git/labs/private",
            ),
        }

        log.info(f"Setting up bare repositories on {self.server}")

        for name, (url, branch, push_path) in repos.items():
            log.info(f"Repository {name}")

            res = ssh_bash(
                self.server,
                f"pontoon-setup-repo '{branch}' '{url}' $HOME/{name} '{push_path}'",
            )
            if res.returncode != 0:
                log.error(
                    f"Unable to set up repository {name}. "
                    f"Is {self.server} accessible and bootstrapped?"
                )
                return False

        return True

    def update_ssh_fingerprints(self) -> bool:
        cmd = "ssh-keyscan $(pontoon-enc --list-hosts)"
        outfile = f"{self.config_dir()}/ssh_known_hosts"

        log.info(f"Updating SSH fingerprints in {outfile}")
        proc = ssh_bash(self.server, cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            log.error("Failed to update SSH fingerprints: %s", proc.stderr)
            return False

        with open(outfile, "w") as known_hosts:
            known_hosts.write(proc.stdout)

        return True
