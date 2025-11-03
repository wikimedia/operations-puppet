#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import sys
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--outfile", type=Path, metavar="FILE.prom", help="Output file")
    parser.add_argument(
        "--clustername", help="Name of the Ganeti cluster", required=True
    )
    parser.add_argument(
        "--cert-path", type=Path, help="Ganeti root certificate", required=True
    )

    args = parser.parse_args()

    registry = CollectorRegistry()

    metric_cert_expiry = Gauge(
        "cert_expiry",
        "Unix timestamp when the Ganeti CA certificate is going to expire",
        namespace="ganeti_ca",
        registry=registry,
        labelnames=["clustername"],
    )

    with (args.cert_path).open("rb") as f:
        root_cert = x509.load_pem_x509_certificate(f.read(), default_backend())

    metric_cert_expiry.labels(args.clustername).set(
        root_cert.not_valid_after.timestamp()
    )

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode("utf-8"))


if __name__ == "__main__":
    sys.exit(main())
