#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import argparse
from pathlib import Path

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile

STATE_PATH = "/var/lib/dnsbox"


def parse_args() -> argparse.Namespace:
    description = (
        "Gathers the state of various dnsbox services to export as Prom metrics"
    )
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "-o",
        "--outfile",
        nargs="?",
        type=Path,
        default="/var/lib/prometheus/node.d/dnsbox_service_state.prom",
    )
    return parser.parse_args()


def get_state() -> dict[str, int]:
    """Iterates over STATE_PATH directory and gets the various state of services."""
    service_states = {}
    for state in Path(STATE_PATH).glob("*.state"):
        # We set a `yes' or `no' for the service state.
        service_state = int(state.read_text().splitlines()[1].strip() == "yes")
        # The file names have _ but the service names should probably be - to
        # match what anycast-hc sets as well.
        service_name = state.name.split(".")[0].replace("_", "-")
        service_states[service_name] = service_state

    return service_states


def main() -> None:
    args = parse_args()
    registry = CollectorRegistry()

    service_states = get_state()

    gauge = Gauge(
        "dnsbox_service_state",
        "Service state: 0 = down, 1 = up",
        ["service_name"],
        registry=registry,
    )

    for service, state in service_states.items():
        gauge.labels(service).set(state)

    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    main()
