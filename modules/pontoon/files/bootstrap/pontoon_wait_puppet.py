#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import os
import shlex
import signal
import subprocess
import sys
import time
from typing import Dict

TIMEOUT_REACHED_RETURNCODE = 124


def puppet_agent_stats() -> Dict[str, float]:
    """
    Collects Puppet agent metrics names in Prometheus format.
    NOTE: Labels are not parsed, metrics are returned verbatim together with their labels.

    Returns:
        Dict[str, float]: A dictionary of Puppet agent metric names -> value
    """
    stats = {}

    p = subs.popen(
        "prometheus-puppet-agent-stats", stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    stdout, _ = p.communicate()
    if p.returncode != 0:
        return stats

    for line in stdout.splitlines():
        line = line.strip().decode("utf-8")
        if line.startswith("#") or " " not in line:
            continue

        metric, value = line.rsplit(" ", 1)
        stats[metric] = float(value)

    return stats


def wait_puppet(timeout: int, resource_change_max_pct: int, retry_sleep: int) -> int:
    """
    Waits for the Puppet agent run to complete within the specified timeout.

    Args:
        timeout (int): The maximum number of seconds to wait for the Puppet run to complete.
        resource_change_max_pct (int): The maximum allowed percentage of changed resources for
                                       a run to be considered successful.
        retry_sleep (int): The number of seconds to wait between status checks.

    Returns:
        int: The final status of the Puppet run. A nonzero value may indicate failure.
    """

    deadline = time.time() + timeout

    while time.time() <= deadline:
        p = subs.popen(shlex.split(f"timeout {timeout} run-puppet-agent --quiet"))
        p.wait()
        # Give up if a single agent run takes longer than our total timeout
        if p.returncode == TIMEOUT_REACHED_RETURNCODE:
            sys.stderr.write("Puppet run timed out, exiting.\n")
            return 1

        # XXX check for a previous run in the not too distant past and skip puppet as needed
        stats = puppet_agent_stats()
        puppet_enabled = stats.get("puppet_agent_enabled", -1)
        resources_changed = stats.get("puppet_agent_resources_changed", -1)
        resources_total = stats.get("puppet_agent_resources_total", -1)

        if -1 in (resources_changed, resources_total, puppet_enabled):
            sys.stderr.write("Unable to get puppet metrics, exiting.\n")
            return 1

        if not puppet_enabled:
            sys.stderr.write("Puppet agent is not enabled, exiting.\n")
            return 1

        if resources_total == 0:
            sys.stderr.write("Puppet failed (zero resources found), retrying.\n")
        else:
            changed_pct = (resources_changed / resources_total) * 100
            if changed_pct <= resource_change_max_pct:
                sys.stderr.write(
                    f"Puppet agent converged ({changed_pct:.2f}% resource change).\n"
                )
                return 0
            else:
                sys.stderr.write(
                    f"Too many resources changed ({changed_pct:.2f}%), retrying.\n"
                )

        time.sleep(retry_sleep)

    return 1


class Subprocesses(object):
    """Minimal wrapper to start/stop subprocesses."""

    def __init__(self):
        self.procs = []

    def popen(self, *args, **kwargs) -> subprocess.Popen:
        p = subprocess.Popen(*args, **kwargs)
        self.procs.append(p)
        return p

    def terminate(self):
        for p in self.procs:
            p.terminate()


subs = Subprocesses()


def signal_handler(sig, frame):
    subs.terminate()
    sys.exit(1)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Wait for Puppet agent to converge.",
    )
    parser.add_argument(
        "--changed-pct",
        type=int,
        default=1,
        help="Percentage of resources changed to consider the agent run successful (0-100).",
    )
    parser.add_argument(
        "--timeout-minutes",
        type=int,
        default=4,
        metavar="TIMEOUT",
        help="Keep running the agent up until TIMEOUT minutes have passed.",
    )
    parser.add_argument(
        "--retry-sleep-seconds",
        type=int,
        default=15,
        help="Number of seconds to wait between puppet runs.",
    )
    return parser.parse_args()


def main() -> int:
    """
    The function continuously checks the status of the Puppet agent run and
    considers it successful if the percentage of changed resources does not
    exceed `resource_change_max_pct`. It retries checking at intervals defined
    by `retry_sleep` seconds until `timeout_minutes` have passed.
    """

    if os.geteuid() != 0:
        print("Error: needs to run as root")
        return 1

    for sig in (
        signal.SIGINT,
        signal.SIGTERM,
        signal.SIGHUP,  # received when the controlling tty quits (e.g. via ssh)
    ):
        signal.signal(sig, signal_handler)

    args = parse_arguments()

    return wait_puppet(
        args.timeout_minutes * 60, args.changed_pct, args.retry_sleep_seconds
    )


if __name__ == "__main__":
    sys.exit(main())
