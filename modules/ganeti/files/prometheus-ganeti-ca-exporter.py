#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
import sys
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.x509.oid import NameOID
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile
from prometheus_client.exposition import generate_latest


def extract_name(name: x509.Name) -> str:
    attributes = name.get_attributes_for_oid(NameOID.COMMON_NAME)
    if len(attributes) > 0:
        return attributes[0].value

    return name.rfc4514_string()


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--outfile", type=Path, metavar="FILE.prom", help="Output file")
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
        labelnames=["subject"],
    )

    with (args.cert_path).open("rb") as f:
        root_cert = x509.load_pem_x509_certificate(f.read(), default_backend())

    metric_cert_expiry.labels(extract_name(root_cert.subject)).set(
        root_cert.not_valid_after.timestamp()
    )

    if args.outfile:
        write_to_textfile(args.outfile, registry)
    else:
        sys.stdout.write(generate_latest(registry).decode("utf-8"))


if __name__ == "__main__":
    sys.exit(main())
