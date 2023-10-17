#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
This script is in charge of exporting the expiry datetime of the argument
x509 certificate, and exposing that metric in a prometheus text file.
"""

import argparse
import sys
from pathlib import Path

from cryptography import x509
from cryptography.x509.oid import NameOID
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cert-path", type=Path, help="Path to the certificate", required=True
    )
    parser.add_argument(
        "--outfile", type=Path, metavar="FILE.prom", help="Output file", required=True
    )
    return parser.parse_args()


def extract_name(cert: x509.Certificate) -> str:
    """Extract the subject name from the argument certificate"""
    name = cert.subject
    attributes = name.get_attributes_for_oid(NameOID.COMMON_NAME)
    if len(attributes) > 0:
        return attributes[0].value
    return name.rfc4514_string()


def main():
    args = parse_args()
    certificate_content = args.cert_path.read_bytes()
    cert = x509.load_pem_x509_certificate(certificate_content)
    cert_subject_name = extract_name(cert)

    registry = CollectorRegistry()
    metric_cert_expiry = Gauge(
        "cert_expiry",
        "Expiry timestamp of the x509 certificate",
        namespace="x509",
        registry=registry,
        labelnames=["subject"],
    )
    metric_cert_expiry.labels(cert_subject_name).set(cert.not_valid_after.timestamp())
    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    sys.exit(main())
