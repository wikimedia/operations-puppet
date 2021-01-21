#!/usr/bin/env python3
"""
Copyright (C) 2019-2020 Giuseppe Lavagetto <glavagetto@wikimedia.org>
Copyright (C) 2021 Kunal Mehta <legoktm@member.fsf.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
"""
import argparse
import os
import sys
import traceback

import requests

# Tell requests to use our non-standard .netrc
os.environ["NETRC"] = "/etc/php7adm.netrc"


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-w", "--warning", help="free space warning threshold",
                        type=int, required=True)
    parser.add_argument("-c", "--critical", help="free space critical threshold",
                        type=int, required=True)
    return parser.parse_args()


def opcache_info():
    req = requests.get(
        "http://localhost:9181/opcache-info",
        headers={"user-agent": "nrpe_check_opcache.py"},
    )
    req.raise_for_status()
    return req.json()


def main():
    args = parse_args()
    info = opcache_info()
    # First check if the opcache is full
    if info["cache_full"]:
        print("CRITICAL: opcache full.")
        return 2
    # Now check for the opcache cache-hit ratio. If it's below 99.85%, it's a critical alert.
    scripts = info["opcache_statistics"]["num_cached_scripts"]
    hits = info["opcache_statistics"]["hits"]
    # Skip the check if the service has been restarted since a few minutes, and we
    # don't have enough traffic to reach the stats.
    # Specifically, we need to have a number of hits that, given the number of scripts,
    # would allow to reach such thresholds.
    threshold = scripts * 10000  # 1 miss out of 10k => 99.99%
    if hits > threshold:
        hit_rate = info["opcache_statistics"]["opcache_hit_rate"]
        if hit_rate < 99.85:
            print("CRITICAL: opcache cache-hit ratio is below 99.85%")
            return 2
        elif hit_rate < 99.99:
            print("WARNING: opcache cache-hit ratio is below 99.99%")
            return 1

    # Now check if the free space is below the critical level
    free_space = info["memory_usage"]["free_memory"] / (1024 * 1024)
    if free_space < args.critical:
        print("CRITICAL: opcache free space is below {args.critical} MB".format(args=args))
        return 2
    elif free_space < args.warning:
        print("WARNING: opcache free space is below {args.warning} MB".format(args=args))
        return 1

    # Haven't bailed yet, everything is good
    print("OK: opcache is healthy")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        # Catch any unexpected errors, like requests or JSON errors
        print("UNKNOWN: {e}".format(e=e))
        traceback.print_exc()
        sys.exit(3)
