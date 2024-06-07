#!/usr/bin/env python3
"""
check_mailman_queue

Copyright 2014 Matanya Moses
Copyright 2015 Daniel Zahn
Copyright 2021 Kunal Mehta <legoktm@debian.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

import argparse
from pathlib import Path
import sys
import traceback
import wmflib.config

# Queues to monitor
QUEUES = ["bounces", "in", "virgin"]


def get_root_dir() -> Path:
    cfg = wmflib.config.load_ini_config("/etc/mailman3/mailman.cfg")
    return Path(cfg["paths.debian"]["var_dir"])


def parse_args():
    parser = argparse.ArgumentParser(description="Check mailman queue sizes")
    for queue in QUEUES:
        parser.add_argument(
            f"{queue}_limit", type=int, help=f"Limit of the {queue} queue"
        )
    parser.add_argument("--mailman3", action="store_true", help="Monitor mailman3 instead")
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.mailman3:
        mailman_base = get_root_dir() / "queue"
    else:
        mailman_base = Path("/var/lib/mailman/qfiles")
    critical_queues = []
    for queue in QUEUES:
        size = len(list((mailman_base / queue).iterdir()))
        limit = getattr(args, f"{queue}_limit")
        if args.debug:
            print(f"{queue}: {size} (limit: {limit})")
        if size > limit:
            critical_queues.append(f"{queue} is {size} (limit: {limit})")
    version = "mailman3" if args.mailman3 else "mailman2"
    if critical_queues:
        print(
            f"CRITICAL: {len(critical_queues)} {version} queues above limits: "
            + ", ".join(critical_queues)
        )
        return 2
    print(f"OK: {version} queues are below the limits")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        # Catch any unexpected errors
        print("UNKNOWN: {e}".format(e=e))
        traceback.print_exc()
        sys.exit(3)
