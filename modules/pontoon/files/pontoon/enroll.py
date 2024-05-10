# SPDX-License-Identifier: Apache-2.0
import logging
import subprocess

from pontoon import Pontoon

log = logging.getLogger()


class Enroller(object):
    def __init__(self, pontoon: Pontoon):
        self.pontoon = pontoon
        self.ssh_cmd = [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=6",
            "-o",
            "StrictHostKeyChecking=no",
        ]
        self.agent_server = pontoon.server_fqdn
        self.pki_san = "pki.discovery.wmnet"

    def enroll(self, host, force=False):
        role = self.pontoon.role_for_host(host)
        if not role:
            log.error("Role for %r not found", host)
            return False

        log.info("Host %r has role %r", host, role)

        if force:
            p = self.pontoon.ssh_bash(self.agent_server, "sudo puppetserver ca clean --certname %s" % host)
        else:
            p = self.pontoon.ssh_bash(
                host,
                "sudo puppet config --section agent print server",
                capture_output=True,
                text=True,
            )
            if p.returncode > 0:
                log.error("Unable to find agent server for %s", host)
                log.error("Stderr: %s", p.stderr)
                log.error("Stdout: %s", p.stdout)
                return False
            if p.stdout.strip() == self.agent_server:
                log.warning("Host %s already enrolled", host)
                return False

        # Bootstrap PKI via puppet cert SAN
        if role == "pki::multirootca":
            p = self.pontoon.ssh_bash(
                host,
                "sudo puppet config --section agent set dns_alt_names %s "
                % self.pki_san,
            )
            if p.returncode > 0:
                log.error("Failed to set dns-alt-names for %s", host)
                return False

        if not self._enroll(host):
            return False

        log.info("Running puppet agent")
        subprocess.run(
            self.ssh_cmd + [host, "--", "sudo puppet agent --test --verbose"]
        )
        # APT sources have likely changed, thus update and run-puppet-agent (now available)
        proc = subprocess.run(
            self.ssh_cmd + [host, "--", "sudo apt -q update && sudo run-puppet-agent"]
        )
        return proc.returncode == 0


    def _enroll(self, host):
        set_master_cmd = (
            "sudo puppet config --section agent set server %s" % self.agent_server
        )
        set_ca_server_cmd = (
            "sudo puppet config --section agent set ca_server %s" % self.agent_server
        )
        wipe_puppet_certs_cmd = "sudo find /var/lib/puppet/ssl -type f -delete"

        enroll_cmd = "&&".join(
            (
                set_master_cmd,
                set_ca_server_cmd,
                wipe_puppet_certs_cmd,
            )
        )

        log.info("Enrolling %s to %s", host, self.agent_server)
        p = self.pontoon.ssh_bash(host, enroll_cmd)
        if p.returncode > 0:
            log.error("Failed to enroll %s to %s", host, self.agent_server)
            return False

        return True
