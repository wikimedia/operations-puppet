#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import click
import logging
import sys
import json
import yaml
import subprocess
import os

from pypuppetdb import connect
from pypuppetdb.api import API
from prometheus_client import (
    CollectorRegistry,
    Gauge,
    push_to_gateway,
    generate_latest
)

PUSHGATEWAY_URL = os.environ["PUSHGATEWAY_URL"]

JOB = os.path.basename(__file__)

logging.basicConfig(level=logging.INFO,
                    format="{levelname} - {message}", style="{")
logger = logging.getLogger()


def pdbquery(db: API, rtype: str) -> list | None:

    try:
        pql = f"""
        resources [parameters, tags]{{
            type = '{rtype}'
        }}
        """

        resources = list(db.pql(pql))
    except Exception:
        logger.error("Error executing PuppetQL query...", exc_info=True)
        resources = None

    return resources


def jq(input: list, filter: str) -> list | None:

    try:
        proc = subprocess.run(
            ["jq", "-r", filter],
            input=json.dumps(input).encode(),
            stdout=subprocess.PIPE,
        )

        results = []
        for line in proc.stdout.decode().strip().split():
            results.append(json.loads(line))

        logger.debug("Applied JQ filter (items: {})...".format(len(results)))
    except Exception:
        logger.error("Error applying jq filter...", exc_info=True)
        results = None

    return results


def count(input: list, uniq: bool = False) -> int:

    try:
        if not uniq:
            count = len(input)
        else:
            count = -1
            stringified = ["#".join(map(lambda x: str(x), i)) for i in input]
            uniqs = set()
            for s in stringified:
                uniqs.add(s)
            count = len(uniqs)

        logger.debug("Counted {} elements...".format(len(input)))
    except Exception:
        logger.error("Error counting elements...", exc_info=True)
        count = -1

    return count


@click.command()
@click.option(
    "--dry-run", is_flag=True, help="If True does not really send metrics"
)
@click.option("--debug", is_flag=True, help="If True enables debugging log")
@click.option(
    "--config",
    "config_path",
    type=click.Path(exists=True),
    default="/etc/pdb-resource-exporter.yml",
    help="Path to configuration file",
)
def main(dry_run, debug, config_path):

    if debug:
        logger.setLevel(logging.DEBUG)

    logger.info("Started execution...")

    logger.info("Reading configs...")
    with open(config_path) as c:
        config = yaml.safe_load(c)

    registry = CollectorRegistry()
    g = Gauge(
        "puppetdb_resource_stats",
        "puppet resource count by type",
        ["type", "queryname", "distinct"],
        registry=registry,
    )
    e = Gauge(
        "puppetdb_resource_stats_errors",
        "bool: True if errors occurred during the last execution",
        ["type", "queryname"],
        registry=registry,
    )

    # The connection is actually established only when a query is submitted
    # There's no need for error handling here
    db = connect()

    for s in config["series"]:
        logger.info("Evaluating {}/{}...".format(s["name"], s["rtype"]))

        errorFound = e.labels(s["rtype"], s["name"])
        itemsNo = -1
        rawdata = pdbquery(db, s["rtype"])

        if rawdata is None:
            errorFound.set(1)
            continue

        logger.info(
            "Applying JQ filter for {}/{}...".format(s["name"], s["rtype"]))
        jqdata = jq(rawdata, s["filter"])

        if jqdata is None:
            errorFound.set(1)
            continue

        logger.info("Counting {}/{} elements...".format(s["name"], s["rtype"]))
        itemsNo = count(jqdata, s["uniq"])
        if itemsNo <= 0:
            errorFound.set(1)
            continue

        logger.info(
            "Adding {}/{} series to metric...".format(s["name"], s["rtype"]))
        g.labels(s["rtype"], s["name"], str(s["uniq"])).set(itemsNo)
        errorFound.set(0)

    db.disconnect()

    logger.debug("Stored series:")
    logger.debug(generate_latest(registry).decode("utf-8"))

    if not dry_run:
        logger.info(
            "Pushing metrics to pushgateway {} (job: {})".format(
                PUSHGATEWAY_URL, JOB)
        )
        push_to_gateway(PUSHGATEWAY_URL, job=JOB, registry=registry)


if __name__ == "__main__":
    sys.exit(main())
