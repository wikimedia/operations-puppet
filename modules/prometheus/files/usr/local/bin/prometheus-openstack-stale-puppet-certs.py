#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import functools
import sys

from pathlib import Path
from subprocess import run

import mwopenstackclients

from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile,
)
from prometheus_client.exposition import generate_latest


@functools.lru_cache()
def get_project_vms(project_id: str):
    servers = (
        mwopenstackclients.Clients("/etc/novaobserver.yaml")
        .novaclient(project_id)
        .servers.list()
    )
    return [server.name for server in servers]


def get_signed_certificates(signed_certs_dir: Path):
    """Returns the CNs for all currently active signed Puppet CA certificates."""
    return [
        path.absolute().with_suffix("").parts[-1]
        for path in signed_certs_dir.glob("*.pem")
    ]


def collect_openstack_cert_data(registry: CollectorRegistry, signed_certs_dir: Path):
    signed_certs = [
        cn.replace(".wmflabs", "1.wikimedia.cloud")
        for cn in get_signed_certificates(signed_certs_dir)
        if (cn.endswith(".wmflabs") or cn.endswith(".wikimedia.cloud"))
    ]

    stalecerts = Gauge(
        "stale_cert",
        "Signed Puppet certificate for a non-existent VM",
        namespace="puppetmaster",
        registry=registry,
        labelnames=("cert_instance", "cert_project"),
    )

    for cn in signed_certs:
        instance, project, *_ = cn.split(".")

        if project == "svc":
            continue

        if instance not in get_project_vms(project):
            stalecerts.labels(instance, project).set(1)


def ssl_dir():
    """Get the puppet server ssl directory"""
    command = "/usr/bin/puppet config --section master print ssldir".split()
    result = run(command, capture_output=True, check=True)
    ssldir = result.stdout.decode().strip()
    return f"{ssldir}/ca/signed"


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--outfile", metavar="FILE.prom", help="Output file (stdout)")

    args = parser.parse_args()

    if args.outfile and not args.outfile.endswith(".prom"):
        parser.error("Output file does not end with .prom")

    registry = CollectorRegistry()
    collect_openstack_cert_data(registry, Path(ssl_dir()))

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode("utf-8"))


if __name__ == "__main__":
    sys.exit(main())
