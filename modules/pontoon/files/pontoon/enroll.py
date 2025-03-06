#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import logging

from pontoon import Pontoon
from pontoon.host import Host
import pontoon.ssh as ssh

log = logging.getLogger()


class Enroller(object):
    def __init__(self, pontoon: Pontoon):
        self.pontoon = pontoon
        self.agent_server = pontoon.server_fqdn
        self.pki_san = "pki.discovery.wmnet"

    def enroll(self, host: Host, force: bool = False) -> bool:
        if force:
            p = ssh.bash(
                self.agent_server, f"sudo puppetserver ca clean --certname {host.fqdn}"
            )
        else:
            p = ssh.bash(
                host.fqdn,
                "sudo puppet config --section agent print server",
                capture_output=True,
                text=True,
            )
            if p.returncode > 0:
                log.error(
                    f"Unable to find agent server for {host.fqdn!r}. "
                    "Is the host reachable over ssh?",
                )
                log.error("Stderr: %s", p.stderr)
                log.error("Stdout: %s", p.stdout)
                return False
            if p.stdout.strip() == self.agent_server:
                log.warning(f"Host {host.fqdn!r} already enrolled")
                return True

        # Bootstrap PKI via puppet cert SAN
        if host.role == "pki::multirootca":
            p = ssh.bash(
                host.fqdn,
                f"sudo puppet config --section agent set dns_alt_names {self.pki_san}",
            )
            if p.returncode > 0:
                log.error(f"Failed to set dns-alt-names for {host.fqdn!r}", host)
                return False

        return self._enroll(host.fqdn)

    def _enroll(self, fqdn: str) -> bool:
        set_master_cmd = (
            "sudo puppet config --section agent set server %s" % self.agent_server
        )
        set_ca_server_cmd = (
            "sudo puppet config --section agent set ca_server %s" % self.agent_server
        )
        wipe_puppet_certs_cmd = "sudo find /var/lib/puppet/ssl -type f -delete"
        # in Cloud VPS agents of a self-hosted puppetserver expect
        # /var/lib/puppet/client/ssl instead of /var/lib/puppet/ssl. See also
        # modules/wmflib/lib/puppet/parser/functions/puppet_ssldir.rb
        agent_ssl_client_link_cmd = "sudo ln -s . /var/lib/puppet/client"

        enroll_cmd = "&&".join(
            (
                set_master_cmd,
                set_ca_server_cmd,
                wipe_puppet_certs_cmd,
                agent_ssl_client_link_cmd,
            )
        )

        log.info(f"Enrolling {fqdn!r} to stack {self.pontoon.name!r}")
        p = ssh.bash(fqdn, enroll_cmd)
        if p.returncode > 0:
            log.error(f"Failed to enroll {fqdn!r} using {self.agent_server!r}")
            return False

        return True
