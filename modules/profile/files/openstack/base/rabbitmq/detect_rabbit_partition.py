#!/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Produce prometheus metrics about rabbitmq network partition.

This assumes a very specific output from the rabbitmqctl command, a section
starting with 'Network Partitions' followed by another section called 'Listeners.'

This is very fragile but so far I haven't found a more straightforward way to
detect this error case.
"""

from pathlib import Path
import subprocess

PROMETHEUS_FILE = Path("/var/lib/prometheus/node.d/rabbitmq_partition.prom")
METRIC_NAME = "rabbitmq_network_partition"


def write_metric(metric):
    with PROMETHEUS_FILE.open("w", encoding="utf-8") as prom_fd:
        prom_fd.write(f"# TYPE {METRIC_NAME} gauge\n")
        prom_fd.write(f"{METRIC_NAME} {metric}\n")


out = subprocess.check_output(["rabbitmqctl", "cluster_status"])
partitions = out.decode("utf8").split("Network Partitions")[1].split("Listeners")[0]

if "none" in partitions:
    write_metric(0)
else:
    write_metric(1)
