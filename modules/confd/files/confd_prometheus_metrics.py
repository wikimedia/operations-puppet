#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import logging
import sys
from pathlib import Path
from typing import Any, Mapping

import toml
import toml.decoder  # type: ignore
from prometheus_client import (  # type: ignore
    CollectorRegistry,
    Gauge,
    write_to_textfile,
)
from prometheus_client.exposition import generate_latest  # type: ignore

log = logging.getLogger()


def _default_metrics(registry: CollectorRegistry, namespace: str = "confd"):
    res = {}
    res["healthy"] = Gauge(
        "resource_healthy",
        "Whether the template resource has run successfully or not.",
        namespace=namespace,
        registry=registry,
        labelnames=["name"],
    )
    res["error_timestamp"] = Gauge(
        "resource_error_timestamp_seconds",
        "The error timestamp for the template resource, or -1 if the resource is healthy.",
        namespace=namespace,
        registry=registry,
        labelnames=["name"],
    )
    return res


def inspect_template_dest(
    resource: Path,
    config: Mapping[Any, Any],
    runpath: Path,
    metrics: Mapping[str, Gauge],
):
    """Make sure this resource's destination is healthy (e.g. can compile)"""

    template_dest = Path(config["template"]["dest"])
    template_dest_mtime = template_dest.stat().st_mtime

    log.debug("Inspecting destination file %s", template_dest)

    if not template_dest.exists():
        log.warning(f"{template_dest} not found")
        metrics["healthy"].labels(resource.name).set(0)
        metrics["error_timestamp"].labels(resource.name).set(-1)
        return

    template_state = list(runpath.glob(f".{template_dest.name}*"))

    if len(template_state) == 0:
        metrics["healthy"].labels(resource.name).set(1)
        metrics["error_timestamp"].labels(resource.name).set(-1)
        return

    for state in template_state:
        state_mtime = state.stat().st_mtime
        if state_mtime > template_dest_mtime:
            log.warning(f"State file {state} newer than {template_dest.name}")
            metrics["healthy"].labels(resource.name).set(0)
            metrics["error_timestamp"].labels(resource.name).set(state_mtime)
            return


def inspect_resources(confd_path: Path, runpath: Path, metrics: Mapping[str, Gauge]):
    """Read all template resources (i.e. confd TOML configuration files) and
    update metrics accordingly."""
    for resource in confd_path.glob("*.toml"):
        try:
            log.debug("Inspecting resource %s", resource)
            config = toml.load(resource)
            inspect_template_dest(resource, config, runpath, metrics)
        except (toml.decoder.TomlDecodeError, FileNotFoundError):
            metrics["healthy"].labels(resource.name).set(0)


def main():
    parser = argparse.ArgumentParser(
        description="Inspect confd configuration and export Prometheus metrics accordingly.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--outfile",
        metavar="FILE.prom",
        default="/var/lib/prometheus/node.d/confd_template.prom",
        help="Output file, use - for stdout",
    )
    parser.add_argument(
        "--confd.path",
        metavar="PATH",
        default="/etc/confd/conf.d",
        help="Read template resource files from PATH",
        dest="confd_path",
    )
    parser.add_argument(
        "--confd.runpath",
        metavar="PATH",
        default="/var/run/confd-template",
        help="Read confd template state from PATH",
        dest="confd_runpath",
    )
    parser.add_argument(
        "-d",
        "--debug",
        action="store_true",
        default=False,
        help="Enable debug logging",
    )
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    registry = CollectorRegistry()
    metrics = _default_metrics(registry)
    inspect_resources(Path(args.confd_path), Path(args.confd_runpath), metrics)

    if args.outfile == "-":
        sys.stdout.write(generate_latest(registry).decode("utf-8"))
    else:
        write_to_textfile(args.outfile, registry)
        log.debug("Wrote metrics to %s", args.outfile)

    return 0


if __name__ == "__main__":
    sys.exit(main())
