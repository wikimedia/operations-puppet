#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

import boto3
import urllib3
import yaml
from urllib3.exceptions import InsecureRequestWarning


def get_block_size(bucket, prefix, s3_client):
    total_size = 0
    paginator = s3_client.get_paginator("list_objects_v2")
    response_iterator = paginator.paginate(Bucket=bucket, Prefix=prefix)

    for page in response_iterator:
        for obj in page.get("Contents", []):
            total_size += obj["Size"]

    return total_size


def get_bucket_blocks(bucket_name, s3_client):
    paginator = s3_client.get_paginator("list_objects_v2")
    response_iterator = paginator.paginate(Bucket=bucket_name, Delimiter="/")

    top_level_directories = [
        obj["Prefix"]
        for page in response_iterator
        for obj in page.get("CommonPrefixes", [])
    ]
    # Find which directories are ULIDs (i.e. Thanos/Prometheus blocks)
    ulids = [
        x for x in top_level_directories if x[0].isdigit() and len(x.strip("/")) == 26
    ]

    return ulids


def get_s3_config(path):
    with open(path) as f:
        conf = yaml.safe_load(f)

    if conf["type"].lower() != "s3":
        raise ValueError(f"Invalid objstore configuration {path}")

    return conf["config"]


def blocks_sizes(config_file, tls_verify, workers):
    if not tls_verify:
        urllib3.disable_warnings(InsecureRequestWarning)

    s3_config = get_s3_config(config_file)
    bucket_name = s3_config["bucket"]
    access_key = s3_config["access_key"]
    secret_key = s3_config["secret_key"]
    endpoint_url = "https://" + s3_config["endpoint"]

    s3_client = boto3.client(
        "s3",
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        endpoint_url=endpoint_url,
        verify=tls_verify,
    )

    blocks = get_bucket_blocks(bucket_name, s3_client)

    print(
        f"Found {len(blocks)} blocks for bucket {bucket_name!r} "
        "at {endpoint_url}. Calculating sizes.",
        file=sys.stderr,
    )

    # Calculate total size for each block
    with ThreadPoolExecutor() as executor:
        blocks_sizes = list(
            executor.map(
                lambda d: get_block_size(bucket_name, d, s3_client),
                blocks,
                max_workers=workers,
            )
        )

    # Display results, ready for import.
    for block, size in zip(blocks, blocks_sizes):
        block = block.strip("/")
        print(f"{block}\t{size / (1024**2):.2f}")

    return 0


def thanos_inspect_bucket(config_file):
    cmd = [
        "thanos",
        "tools",
        "bucket",
        "inspect",
        "--objstore.config-file",
        config_file,
        "--output",
        "tsv",
    ]
    print(f"Running {cmd!r}", file=sys.stderr)
    p = subprocess.run(cmd)
    return p.returncode


def main():
    parser = argparse.ArgumentParser(
        description="Export Thanos bucket information.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--kind",
        dest="kind",
        default="blocks",
        choices=["blocks", "sizes"],
        help="The data type to export.",
    )
    parser.add_argument(
        "--tls-verify",
        dest="tls_verify",
        default=True,
        type=bool,
        help="Verify TLS connections.",
    )
    parser.add_argument(
        "--objstore.config-file",
        dest="config_file",
        default="/etc/thanos-bucket-web/objstore.yaml",
        help="Path to Thanos objstore configuration.",
    )
    parser.add_argument(
        "--workers",
        dest="workers",
        default=os.cpu_count() / 2,
        help="How many workers/connections used to scan for block sizes.",
    )
    args = parser.parse_args()

    if args.kind == "blocks":
        return thanos_inspect_bucket(args.config_file)
    elif args.kind == "sizes":
        return blocks_sizes(args.config_file, args.tls_verify, args.workers)


if __name__ == "__main__":
    sys.exit(main())
