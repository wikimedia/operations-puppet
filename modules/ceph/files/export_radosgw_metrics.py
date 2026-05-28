#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
This script will measure and report stats for S3 buckets and their associated owners
"""

import argparse
import json
import subprocess
from pathlib import Path

from prometheus_client import Gauge, CollectorRegistry, write_to_textfile

MAIN_NS = "radosgw"
BUCKET_NS = f"{MAIN_NS}_bucket"
USER_NS = f"{MAIN_NS}_user"


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--outfile", type=Path, metavar="FILE.prom", help="Output file", required=True
    )
    return parser.parse_args()


def list_buckets() -> list[str]:
    cmd = ["radosgw-admin", "bucket", "list"]
    output = subprocess.run(cmd, capture_output=True, check=True, encoding="utf-8")
    return json.loads(output.stdout)


def list_users() -> list[str]:
    cmd = ["radosgw-admin", "user", "list"]
    output = subprocess.run(cmd, capture_output=True, check=True, encoding="utf-8")
    return json.loads(output.stdout)


def get_bucket_stats(bucket_name: str) -> dict:
    cmd = ["radosgw-admin", "bucket", "stats", f"--bucket={bucket_name}"]
    output = subprocess.run(cmd, capture_output=True, check=True, encoding="utf-8")
    return json.loads(output.stdout)


def get_user_stats(user_name: str) -> dict:
    cmd = ["radosgw-admin", "user", "stats", f"--uid={user_name}"]
    output = subprocess.run(cmd, capture_output=True, check=True, encoding="utf-8")
    return json.loads(output.stdout)


def collect_bucket_stats(registry: CollectorRegistry):
    BUCKET_USAGE_SIZE_ACTUAL = Gauge(
        "size_actual",
        "Actual data size of the bucket content",
        namespace=BUCKET_NS,
        registry=registry,
        labelnames=["bucket", "owner"],
    )
    BUCKET_USAGE_NUM_OBJECTS = Gauge(
        "num_objects",
        "Number of objects in the bucket",
        namespace=BUCKET_NS,
        registry=registry,
        labelnames=["bucket", "owner"],
    )
    for bucket in list_buckets():
        bucket_stats = get_bucket_stats(bucket)
        if not bucket_stats["usage"]:
            continue
        BUCKET_USAGE_SIZE_ACTUAL.labels(
            bucket=bucket,
            owner=bucket_stats["owner"],
        ).set(bucket_stats["usage"]["rgw.main"]["size_actual"])
        BUCKET_USAGE_NUM_OBJECTS.labels(
            bucket=bucket,
            owner=bucket_stats["owner"],
        ).set(bucket_stats["usage"]["rgw.main"]["num_objects"])


def collect_user_stats(registry: CollectorRegistry):
    USER_USAGE_SIZE_ACTUAL = Gauge(
        "size_actual",
        "Actual data size of all the user's bucket content",
        namespace=USER_NS,
        registry=registry,
        labelnames=["user"],
    )
    USER_USAGE_NUM_OBJECTS = Gauge(
        "num_objects",
        "Total number of objects in the user's buckets",
        namespace=USER_NS,
        registry=registry,
        labelnames=["user"],
    )
    for user in list_users():
        user_stats = get_user_stats(user)
        USER_USAGE_SIZE_ACTUAL.labels(
            user=user,
        ).set(user_stats["stats"]["size_actual"])
        USER_USAGE_NUM_OBJECTS.labels(
            user=user,
        ).set(user_stats["stats"]["num_objects"])


def main():
    args = parse_args()
    registry = CollectorRegistry()
    collect_bucket_stats(registry)
    collect_user_stats(registry)
    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    main()
