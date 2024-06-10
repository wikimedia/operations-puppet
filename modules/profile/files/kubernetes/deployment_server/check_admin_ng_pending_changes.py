#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
This script is in charge of exporting whether admin_ng changes are pending
for a given Kubernetes cluster, and exposing that metric in a prometheus text file.

If the metric has a non-zero value, then a diff is pending.
"""

import argparse
import sys
import subprocess

from pathlib import Path
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--environment", type=str, help="helmfile environment name", required=True
    )
    parser.add_argument(
        "--outfile", type=Path, metavar="FILE.prom", help="Output file", required=True
    )
    return parser.parse_args()


def check_admin_ng_pending_changes(environment: str) -> int:
    cmd = [
        "/usr/bin/helmfile",
        "--file",
        "/srv/deployment-charts/helmfile.d/admin_ng/helmfile.yaml",
        "-e",
        environment,
        "diff",
        "--detailed-exitcode",
    ]
    # We capture the output to avoid it leaking to the journalctl logs
    output = subprocess.run(cmd, capture_output=True)
    return output.returncode


def main():
    args = parse_args()
    pending_changes = check_admin_ng_pending_changes(args.environment)
    registry = CollectorRegistry()
    metric_cert_expiry = Gauge(
        "admin_ng_pending_changes",
        "Pending admin_ng helmfile changes",
        namespace="helmfile",
        registry=registry,
        labelnames=["cluster"],
    )
    metric_cert_expiry.labels(args.environment).set(pending_changes)
    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    sys.exit(main())
