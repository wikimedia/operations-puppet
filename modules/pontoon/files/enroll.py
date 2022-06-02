#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import logging
import os
import shlex
import subprocess
import time

from enc import Pontoon

log = logging.getLogger()


class EnrollError(Exception):
    pass


class Enroller(object):
    def __init__(self, pontoon):
        self.pontoon = pontoon
        self.ssh_cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=6"]
        self.agent_server = pontoon.hosts_for_role("puppetmaster::pontoon")[0]

    def wait_host_access(self, host):
        deadline = time.time() + 60 * 3

        log.info("Waiting for %s to be accessible...", host)
        while time.time() < deadline:
            p = subprocess.run(
                ["ssh", "-o", "ConnectTimeout=6", host, "sudo id"],
                stdout=subprocess.DEVNULL,
            )
            if p.returncode == 0:
                return True
            time.sleep(10)
        return False

    def enroll(self, host, force=False):
        role = self.pontoon.role_for_host(host)
        if not role:
            log.error("Role for %r not found", host)
            return False

        log.info("Host %r has role %r", host, role)

        if force:
            p = self._ssh_bash(self.agent_server, "sudo puppet cert clean %s" % host)
        else:
            if not self.wait_host_access(host):
                raise EnrollError("Unable to access %s", host)

            p = self._ssh_bash(
                host,
                "sudo puppet config --section agent print server",
                capture_output=True,
                text=True,
            )
            if p.returncode > 0:
                log.error("Unable to find agent server for %s", host)
                return False
            if p.stdout.strip() == self.agent_server:
                log.warning("Host %s already enrolled", host)
                return False

        if not self._enroll(host):
            return False

        log.info("Running puppet agent")
        subprocess.run(self.ssh_cmd + [host, "--", "sudo puppet agent --test --verbose"])
        # APT sources have likely changed, thus update and run-puppet-agent (now available)
        subprocess.run(self.ssh_cmd + [host, "--", "sudo apt -q update && sudo run-puppet-agent"])

    def _ssh_bash(self, host, cmd, *args, **kwargs):
        return subprocess.run(
            self.ssh_cmd + [host, "bash", "-xc", shlex.quote(cmd)], *args, **kwargs
        )

    def _enroll(self, host):
        set_master_cmd = (
            "sudo puppet config --section agent set server %s" % self.agent_server
        )
        set_ca_server_cmd = (
            "sudo puppet config --section agent set ca_server %s" % self.agent_server
        )
        # Make puppet_ssldir happy with a compat symlink
        ssldir_compat_cmd = """
        [ -h /var/lib/puppet/client ] || { \
            sudo ln -s /var/lib/puppet /var/lib/puppet/client; \
        }
        """

        wipe_puppet_certs_cmd = "sudo find /var/lib/puppet/ssl -type f -delete"

        # flip master and wipe certs
        enroll_cmd = "&&".join(
            (set_master_cmd, set_ca_server_cmd, wipe_puppet_certs_cmd, ssldir_compat_cmd)
        )

        log.info("Enrolling %s to %s", host, self.agent_server)
        p = self._ssh_bash(host, enroll_cmd)
        if p.returncode > 0:
            log.error("Failed to enroll %s to %s", host, self.agent_server)
            return False

        return True


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)

    parser = argparse.ArgumentParser(description="Enroll host in a Pontoon stack")
    parser.add_argument(
        "fqdn", type=str, default=None, nargs="+", help="The fqdn(s) to enroll"
    )
    parser.add_argument(
        "-s",
        "--stack",
        type=str,
        metavar="NAME",
        default=os.environ.get("PONTOON_STACK"),
        help="Target Pontoon stack",
    )
    parser.add_argument(
        "-f",
        "--force",
        default=False,
        action="store_true",
        help="Pretend no hosts are enrolled already",
    )
    args = parser.parse_args()

    if not args.stack:
        parser.error("No --stack specified")

    scriptdir = os.path.dirname(os.path.realpath(__file__))

    # XXX include 'stack' in Pontoon
    config = os.path.join(scriptdir, args.stack, "rolemap.yaml")
    with open(config, encoding="utf-8") as f:
        p = Pontoon(f)

    e = Enroller(p)
    for host in args.fqdn:
        e.enroll(host, force=args.force)
