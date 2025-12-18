#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
Extracts service discovery types (Active/Active or Active/Passive)
and exposes that metric in a prometheus text file for the node exporter.
"""

import sys
import argparse
from pathlib import Path
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile

from spicerack import Spicerack


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--outfile",
        type=Path,
        metavar="FILE.prom",
        help="Output file (e.g., /var/lib/prometheus/node.d/discovery_types.prom)",
        required=True
    )
    return parser.parse_args()


def export_discovery_types(outfile: Path):
    spicerack = Spicerack()
    catalog = spicerack.service_catalog()

    registry = CollectorRegistry()
    metric = Gauge(
        "wmf_dnsdiscovery_service_active_active",
        "1 if Active/Active, 0 if Active/Passive",
        registry=registry,
        labelnames=["service"],
    )

    for service in catalog:
        # Only process production services with discovery records
        if service.discovery is None or service.state != "production":
            continue

        for record in service.discovery:
            # Export Active/Active as 1, Active/Passive as 0
            val = 1 if record.active_active else 0

            # The dnsdisc name serves as the unique key
            metric.labels(service=record.dnsdisc).set(val)

    write_to_textfile(outfile, registry)


def main():
    args = parse_args()
    try:
        export_discovery_types(args.outfile)
    except Exception as e:
        print(f"Error exporting discovery types: {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
