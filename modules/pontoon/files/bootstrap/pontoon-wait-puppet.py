#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import shlex
import subprocess
import sys
import time
from typing import Dict


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
        default=3,
        metavar='TIMEOUT',
        help="Keep running the agent up until TIMEOUT minutes have passed.",
    )
    parser.add_argument(
        "--retry-delay-seconds",
        type=int,
        default=15,
        help="Number of seconds to wait between puppet runs.",
    )
    return parser.parse_args()


def puppet_agent_stats() -> Dict[str, float]:
    stats = {}

    p = subprocess.run(
        "prometheus-puppet-agent-stats", stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    p.check_returncode()

    for line in p.stdout.splitlines():
        line = line.strip().decode("utf-8")
        if line.startswith("# "):
            continue
        # not 100% correct because label values can have spaces
        key, value = line.split()
        stats[key] = float(value)
    return stats


def main() -> int:
    args = parse_arguments()

    start_time = time.time()
    timeout_seconds = args.timeout_minutes * 60
    deadline = start_time + timeout_seconds

    while time.time() <= deadline:
        p = subprocess.run(
            shlex.split(f"timeout {timeout_seconds} run-puppet-agent --quiet")
        )
        # No point in trying again if a single agent run takes longer than our total timeout
        if p.returncode == 124:
            sys.stderr.write("Puppet run timed out, exiting.\n")
            return 1

        stats = puppet_agent_stats()

        puppet_enabled = stats.get("puppet_agent_enabled", -1)
        resources_changed = stats.get("puppet_agent_resources_changed", -1)
        resources_total = stats.get("puppet_agent_resources_total", -1)

        if resources_changed == -1 or resources_total == -1 or puppet_enabled == -1:
            sys.stderr.write("Unable to get resource changed metrics, exiting.\n")
            return 1

        if not puppet_enabled:
            sys.stderr.write("Puppet agent is not enabled, exiting.\n")
            return 1

        if resources_total > 0:
            changed_pct = resources_changed / resources_total * 100
            if changed_pct <= args.changed_pct:
                sys.stderr.write(
                    f"Last puppet run changed {changed_pct:.2f}% resources, all done.\n"
                )
                return 0
            else:
                sys.stderr.write(
                    f"Too many resources changed ({changed_pct:.2f}%), retrying.\n"
                )
        else:
            sys.stderr.write("Puppet failed (zero resources found), retrying.\n")

        time.sleep(args.retry_delay_seconds)

    return 1


if __name__ == "__main__":
    sys.exit(main())
