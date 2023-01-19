#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import subprocess
import sys
from argparse import ArgumentParser, Namespace
from pathlib import Path

from dateutil import parser as date_parser
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest


def get_args() -> Namespace:
    """Parse arguments"""
    parser = ArgumentParser()
    parser.add_argument(
        "--outfile", metavar="FILE.prom", type=Path, help="Output file (stdout)"
    )
    return parser.parse_args()


def main() -> int:
    args = get_args()

    registry = CollectorRegistry()

    metric_expiration_timestamp = Gauge(
        "expiration_timestamp",
        "Date when this certificate expires",
        namespace="kubeadm_certs",
        registry=registry,
        labelnames=["ca", "certificate"],
    )

    output = subprocess.check_output(
        ["/usr/bin/kubeadm", "certs", "check-expiration"]
    ).decode("utf-8")

    has_ca = False
    # unfortunately this tool has no json or yaml output mode,
    # so we need to parse the output intended for humans
    for line in output.split("\n"):
        if line == "" or line.startswith("[check-expiration]"):
            continue

        if line.startswith("CERTIFICATE"):
            has_ca = line.startswith("CERTIFICATE AUTHORITY")
            continue

        # split the space-separated columns
        data = [item.strip() for item in line.split("   ") if item.strip() != ""]

        name = data[0]
        date = date_parser.parse(data[1])

        # the fourth column is the CA name for certificates, and the "externally managed" flag for
        # CAs. this will represent CA certificates as an empty string
        ca = "" if has_ca else data[3]

        metric_expiration_timestamp.labels(ca, name).set(int(date.timestamp()))

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode("utf-8"))

    return 0


if __name__ == "__main__":
    sys.exit(main())
