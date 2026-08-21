#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import json
import logging
import os
import subprocess
from dataclasses import dataclass
from typing import Callable, List, Literal, Optional

import pontoon.ssh as ssh
from pontoon import Pontoon
from pontoon.cloudvps import CloudVPS
from pontoon.enroll import Enroller
from pontoon.host import Filter, Host
from pontoon.rolegroups import RoleGroups
from pontoon.util import wait_subprocesses
from ruamel.yaml import YAML

log = logging.getLogger()
WAIT_PUPPET_TIMEOUT_MINUTES = 30


@dataclass
class WaitPuppetResult:
    fqdn: str
    status: str
    stdout: str
    stderr: str


class Controller(object):
    def __init__(self, pontoon: Pontoon, cloud: CloudVPS):
        self._rolegroups: Optional[RoleGroups] = None
        self.yaml = YAML()
        self.pontoon = pontoon
        self.cloud = cloud

    @property
    def server(self) -> Optional[str]:
        return self.pontoon.server_fqdn

    @property
    def stack_hosts(self) -> List[Host]:
        """Return hosts defined in the stack"""
        res = []
        for fqdn, role in self.pontoon.host_map().items():
            res.append(Host(fqdn, role))
        return res

    def cloud_hosts(self, scope: Literal["stack", "project"]) -> List[Host]:
        """Return hosts running in cloud for the given scope"""
        res = []
        hostmap = self.pontoon.host_map()

        for fqdn in self.cloud.fqdns:
            role = hostmap.get(fqdn, "unknown")
            if scope == "stack" and fqdn not in hostmap:
                continue
            res.append(Host(fqdn, role))
        return res

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

    # XXX investigate how remove_rolegroup could look like
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

    def wait_puppet(self, hosts: Filter) -> tuple[bool, list[WaitPuppetResult]]:
        """Wait for puppet runs to finish on hosts.

        Args:
            hosts (Filter): The hosts to wait for

        Returns:
            bool: True if all hosts succeeded, False otherwise
            List[WaitPuppetResult]: List of results for each host
        """

        def commands_for_hosts(hosts: Filter):
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
                        f"UserKnownHostsFile={ssh.KNOWN_HOSTS_PATH()}",
                        "-o",
                        "RequestTty=force",  # make sure remote processes get SIGHUP on exit
                        "-o",
                        f"ConnectTimeout={ssh.CONNECT_TIMEOUT_SECONDS}",
                        host.fqdn,
                        f"sudo pontoon-wait-puppet --timeout-minutes {WAIT_PUPPET_TIMEOUT_MINUTES}",
                    ],
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
                yield host.fqdn, proc

        log.info(
            f"Waiting for puppet to converge on {len(hosts)} hosts. "
            f"(up to {WAIT_PUPPET_TIMEOUT_MINUTES} minutes)"
        )

        results = wait_subprocesses(
            commands_for_hosts(hosts), timeout=60 * WAIT_PUPPET_TIMEOUT_MINUTES
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

    def bootstrap_stack(
        self,
        local_rev: str,
        accept_ssh_key: bool = False,
        quiet: bool = True,
    ) -> bool:
        if not self.server:
            log.error(
                f"Server not found for {self.pontoon.name}, does the stack exist?"
            )
            return False

        host = Host(self.server, "puppetserver::pontoon")
        if host.fqdn not in self.cloud.fqdns:
            self.cloud.create_hosts(hosts=Filter([host]))
            ok = ssh.wait_hosts_access({host.fqdn})
            if not ok:
                log.error(f"Unable to access {self.server}")
                return False

        if not ssh.host_key_known(host):
            ok = ssh.trust_host(host, accept_ssh_key)
            if not ok:
                log.error(f"Failed to trust {host}")
                return False

        log.info(f"Bootstrapping {self.server} for stack {self.pontoon.name}")
        bootstrap_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "bootstrap.sh"
        )
        status = ssh.scp(bootstrap_path, f"{self.server}:")
        if status.returncode != 0:
            log.error("Error copying bootstrap.sh")
            return False

        proc = ssh.bash(
            self.server,
            f"sudo ./bootstrap.sh --check {self.pontoon.name}",
        )

        if proc.returncode == 2:
            log.info("Bootstrap already completed.")
            return True
        elif proc.returncode > 0:
            log.error("Error checking for bootstrap completed.")
            return False

        # Users can provide their code/data in $HOME/bootstrap
        send_local_checkout = f"""
        set -o pipefail ; cd $(git rev-parse --show-toplevel) && \
            git archive --format tgz {local_rev} | \
                ssh -q -o UserKnownHostsFile={ssh.KNOWN_HOSTS_PATH()} {self.server} \
                    'install -d bootstrap/puppet && tar zxf - -C bootstrap/puppet'
        """
        log.info(f"Sending local checkout of {local_rev} to {self.server}")
        returncode = subprocess.call(
            ["bash", "-c", send_local_checkout], cwd=self.pontoon.base_path
        )
        if returncode != 0:
            log.error("Error sending local checkout")
            return False

        log.info(f"Bootstrapping {self.server}")
        proc = ssh.bash(self.server, f"sudo ./bootstrap.sh {self.pontoon.name}")

        if proc.returncode != 0:
            log.error(f"Error running bootstrap.sh on {self.server}")
            return False

        log.info(f"Running puppet agent on {self.server}")
        # allowed to fail
        ssh.bash(
            self.server,
            f"sudo puppet agent --onetime --no-daemonize --no-splay {'' if quiet else '--verbose'}",
        )

        log.info(f"Verifying bootstrap on {self.server}")
        proc = ssh.bash(
            self.server, f"sudo ./bootstrap.sh --verify {self.pontoon.name}"
        )
        if proc.returncode != 0:
            log.error(f"Error verifying bootstrap on {self.server}")
            return False

        return True

    def destroy_hosts(self, hosts: Filter) -> bool:
        ok = True

        for host in hosts:
            self.cloud.destroy_host(host)

        fqdns = {h.fqdn for h in hosts}
        if self.server in fqdns:
            # we're removing the server, nuke ssh_known_hosts because we won't
            # be able to 'pontoonctl ssh-keyscan' again anyways
            try:
                os.unlink(f"{ssh.KNOWN_HOSTS_PATH()}")
            except FileNotFoundError:
                pass  # not present or already gone
        else:
            # It is ok for this to fail: an host can exist in cloud and not in puppet
            ssh.bash(
                self.server, f"sudo puppetserver ca clean --certname {','.join(fqdns)}"
            )

            for host in hosts:
                if not ssh.host_key_known(host):
                    continue
                res = ssh.untrust_host(host)
                if ok and not res:
                    ok = False

        # XXX better error reporting
        return ok

    def create_hosts(
        self,
        hosts: Filter,
        skip_enroll: bool = False,
        no_prompt: bool = False,
    ) -> bool:
        """Create hosts for roles in the Pontoon stack."""
        ok = self.cloud.create_hosts(hosts)
        if not ok:
            return False

        ok = ssh.wait_hosts_access({h.fqdn for h in hosts})
        if not ok:
            return False

        self.update_ssh_fingerprints(accept_ssh_key=no_prompt)

        if skip_enroll:
            return ok

        return self._enroll_hosts(hosts)

    def _enroll_hosts(self, hosts: Filter, force: bool = False) -> bool:
        ok = True
        e = Enroller(self.pontoon)
        for host in hosts:
            if not e.enroll(host, force):
                ok = False
            # The first puppet run can fail at enrollment time!
            # To be able to recover in a user-friendly manner, install
            # pontoon-wait-puppet now. It can be used later to wait for puppet
            # to be successful and converge.
            self._install_wait_puppet(host)
        return ok

    def _install_wait_puppet(self, host: Host) -> bool:
        wait_puppet_path = os.path.join(
            self.pontoon.base_path, "bootstrap", "pontoon_wait_puppet.py"
        )
        status = ssh.scp(wait_puppet_path, f"{host.fqdn}:/tmp/pontoon_wait_puppet.py")
        if status.returncode != 0:
            log.error(f"Error copying {wait_puppet_path}")
            return False

        p = ssh.bash(
            host.fqdn,
            "sudo install -m755 /tmp/pontoon_wait_puppet.py /usr/local/bin/pontoon-wait-puppet",
        )
        if p.returncode != 0:
            log.error("Failed to install pontoon-wait-puppet")
            return False

        return True

    def enroll_hosts(
        self, hosts: Filter, force: bool = False, quiet: bool = True
    ) -> bool:
        """Set hosts as part of the stack and run puppet."""

        if force:
            log.info(f"Forcing enroll on {len(hosts)} hosts")
            # pretend no hosts are enrolled when force is applied
            targets = hosts.apply(lambda _: True)
        else:
            log.info("Looking for hosts to enroll")
            targets = hosts.apply(hosts.not_(self._signed_hosts_filter))

        if len(targets) == 0:
            log.info("No hosts to enroll")
            return True

        # Abort if hosts are not known yet to Pontoon ENC on the server
        unknown_to_enc = targets.apply(targets.not_(self._enc_hosts_filter))
        if len(unknown_to_enc) > 0:
            log.error(
                "The following hosts need enrolling and could not be found "
                "on Pontoon server:"
            )
            for host in unknown_to_enc:
                log.error(f"  {host.fqdn}")
            log.error("Make sure you have pushed an updated rolemap.yaml")
            return False

        ok = self._enroll_hosts(targets, force)
        if not ok:
            log.error("Failed to enroll")
            return False

        # Also run puppet to be nice to the user, i.e. when `pontoonctl enroll-hosts`
        # is done, then the hosts are ready to go.
        # XXX add option to run puppet concurrently on the hosts
        for host in targets:
            log.info(f"Running puppet agent on {host.fqdn}")
            run_puppet_cmd = (
                f"sudo puppet agent --onetime --no-daemonize "
                f"--no-splay {'' if quiet else '--verbose'}"
            )
            ssh.bash(
                host.fqdn,
                run_puppet_cmd,
            )
            # sources have likely changed, thus update and run puppet again
            proc = ssh.bash(
                host.fqdn,
                f"sudo apt {'-qqq' if quiet else ''} update && {run_puppet_cmd}",
            )
            if ok:
                ok = proc.returncode == 0

        return ok

    @property
    def _signed_hosts_filter(self) -> Callable[[Host], bool]:
        """Filter hosts if they have been signed by Puppet server"""
        proc = ssh.bash(
            self.server,
            "sudo puppetserver ca list --format json --all",
            capture_output=True,
            text=True,
        )
        try:
            ca_list = json.loads(proc.stdout)
        except json.decoder.JSONDecodeError:
            log.error(f"Unable to get list of signed hosts from {proc.stdout!r}")
            return lambda host: False

        signed_fqdns = {x["name"] for x in ca_list["signed"] if x["state"] == "signed"}

        return lambda host: host.fqdn in signed_fqdns

    @property
    def _enc_hosts_filter(self) -> Callable[[Host], bool]:
        """Filter hosts if they are known to Pontoon ENC"""
        proc = ssh.bash(
            self.server,
            "pontoon-enc --list-hosts",
            capture_output=True,
            text=True,
        )
        known_fqdns = proc.stdout.split("\n")
        return lambda host: host.fqdn in known_fqdns

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

            res = ssh.bash(
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

    def reboot_hosts(
        self, hosts: Filter, reboot_type: Literal["hard", "soft"], block: bool = True
    ) -> bool:
        for host in hosts:
            self.cloud.reboot_host(host, reboot_type)

        if not block:
            return True

        return ssh.wait_hosts_access({h.fqdn for h in hosts})

    def update_ssh_fingerprints(self, accept_ssh_key: bool = False) -> bool:
        cmd = "ssh-keyscan -t ecdsa,ed25519 $(pontoon-enc --list-hosts)"
        outfile = f"{ssh.KNOWN_HOSTS_PATH()}"
        server = Host(f"{self.server}", "pontoon::puppetmaster")

        log.info(f"Updating SSH fingerprints in {outfile}.")
        while True:
            proc = ssh.bash(server.fqdn, cmd, capture_output=True, text=True)
            if proc.returncode == 0:
                log.info(f"Updated {outfile} successfully.")
                break

            if proc.returncode == 255 and not ssh.host_key_known(server):
                log.warning(f"The host key for {server.fqdn} is missing.")
                ssh.trust_host(server, accept_ssh_key)
                continue

            log.error("Failed to update SSH fingerprints: %s", proc.stderr)
            return False

        with open(outfile, "w") as known_hosts:
            known_hosts.write(proc.stdout)

        return True

    def join_stack(self, accept_ssh_key: bool = False) -> bool:
        if not self.server:
            log.error(f"Server not found for {self.pontoon.name}, unable to join")
            return False

        server = Host(self.server, "puppetserver::pontoon")
        if not ssh.host_key_known(server):
            ok = ssh.trust_host(server, accept_ssh_key)
            if not ok:
                log.error(f"Failed to trust {server}")
                return ok

        ok = self.setup_remote_repositories()
        if not ok:
            log.error("Error setting up remote repositories")
            return ok

        return ok
