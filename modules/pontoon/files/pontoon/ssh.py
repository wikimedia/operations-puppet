#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import shlex
import subprocess
import time
import logging
from typing import Set
from pontoon.host import Host
from pontoon import SYS_CONFIG_PATH

CONNECT_TIMEOUT_SECONDS = 6
HOSTS_ACCESS_TIMEOUT_MINUTES = 5

log = logging.getLogger()


# See base.SYS_CONFIG_PATH on why this is a function and not a module attribute
def KNOWN_HOSTS_PATH():
    return SYS_CONFIG_PATH().joinpath("ssh_known_hosts")


def bash(fqdn, cmd, *args, **kwargs) -> subprocess.CompletedProcess[str]:
    ssh_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "RequestTty=force",
        "-o",
        f"UserKnownHostsFile={KNOWN_HOSTS_PATH()}",
        "-o",
        f"ConnectTimeout={CONNECT_TIMEOUT_SECONDS}",
    ]
    return _retry_subprocess(
        ssh_cmd + [fqdn, "bash", "-c", shlex.quote(cmd)], *args, **kwargs
    )


def wait_hosts_access(hosts: Set[str]) -> bool:
    def proc_for_host(host):
        return subprocess.Popen(
            [
                "ssh",
                "-q",
                "-o",
                "UserKnownHostsFile=/dev/null",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "BatchMode=yes",
                "-o",
                f"ConnectTimeout={CONNECT_TIMEOUT_SECONDS}",
                host,
                "sudo id",
            ],
            stdout=subprocess.DEVNULL,
        )

    procs = {h: proc_for_host(h) for h in hosts}

    deadline = time.time() + 60 * HOSTS_ACCESS_TIMEOUT_MINUTES
    while time.time() < deadline:
        done = []
        for host, proc in procs.items():
            status = proc.poll()
            if status is None:
                continue
            if status == 0:
                done.append(host)
            else:
                procs[host] = proc_for_host(host)
        for host in done:
            del procs[host]

        if len(procs) == 0:
            return True

        hosts_left = {h for h in procs.keys()}
        log.info(
            f"Awaiting access (max {HOSTS_ACCESS_TIMEOUT_MINUTES}m) for {len(hosts_left)} hosts: "
            f"{', '.join(hosts_left)}"
        )
        time.sleep(15)

    log.warning(f"Hosts not accessible past deadline: {list(procs.keys())!r}")
    return False


def trust_host(host: Host, accept: bool = False) -> bool:
    """Add the host's SSH host key to Pontoon's known_hosts"""

    if not accept:
        log.info(f"Logging into {host.fqdn}. Please verify and accept the host key.")

    p = _retry_subprocess(
        [
            "ssh",
            "-q",
            "-o",
            f"StrictHostKeyChecking={'accept-new' if accept else 'ask'}",
            "-o",
            "HashKnownHosts=no",
            "-o",
            f"UserKnownHostsFile={KNOWN_HOSTS_PATH()}",
            f"{host.fqdn}",
            "true",
        ]
    )

    return p.returncode == 0


def untrust_host(host: Host) -> bool:
    """Remove the host's SSH host key to Pontoon's known_hosts"""

    log.info(f"Removing host key for {host.fqdn!r}")
    p = subprocess.run(
        [
            "ssh-keygen",
            "-q",
            "-f",
            f"{KNOWN_HOSTS_PATH()}",
            "-R",
            f"{host.fqdn}",
        ],
        stdout=subprocess.DEVNULL,
    )
    return p.returncode == 0


def host_key_known(host: Host) -> bool:
    p = subprocess.run(
        [
            "ssh-keygen",
            "-q",
            "-f",
            f"{KNOWN_HOSTS_PATH()}",
            "-F",
            f"{host.fqdn}",
        ],
        stdout=subprocess.DEVNULL,
    )
    return p.returncode == 0


def host_access_ok(host: Host) -> bool:
    """Can we ssh to the server ok unattended? In other words is the host key known?"""
    p = _retry_subprocess(
        [
            "ssh",
            "-q",
            "-o",
            "BatchMode=yes",
            "-o",
            f"UserKnownHostsFile={KNOWN_HOSTS_PATH()}",
            f"{host.fqdn}",
            "true",
        ]
    )
    return p.returncode == 0


def host_access_ok_user(host: Host) -> bool:
    """Can the user access the host unattended? If not, the ssh client doesn't
    have default access to Pontoon' ssh_known_hosts."""
    p = _retry_subprocess(["ssh", "-q", "-o", "BatchMode=yes", f"{host.fqdn}", "true"])
    return p.returncode == 0


def scp(src: str, dest: str, *args, **kwargs) -> subprocess.CompletedProcess:
    return _retry_subprocess(
        [
            "scp",
            "-q",
            "-o",
            f"UserKnownHostsFile={KNOWN_HOSTS_PATH()}",
            src,
            dest,
        ],
        *args,
        **kwargs,
    )


def _retry_subprocess(
    cmd: list[str],
    retries: int = 2,
    delay: int = 3,
    *args,
    **kwargs,
) -> subprocess.CompletedProcess:
    """Run a command and retry on failure."""
    for attempt in range(retries):
        p = subprocess.run(cmd, *args, **kwargs)
        if p.returncode == 0:
            return p
        log.warning(f"Command failed: {p.returncode}. Retrying in {delay} seconds...")
        time.sleep(delay)
    return p
