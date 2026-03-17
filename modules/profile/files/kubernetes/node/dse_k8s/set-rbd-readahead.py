#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Brian King (inflatador)
"""
set-rbd-readahead.py: Runs on K8s workers. Upon invocation, it will search for
containers named "opensearch," then find each container's OpenSearch datadir at OS_DATA_PATH.

Next, it will resolve the datadir to a Ceph RBD block device, and set the readahead value
to TARGET_READAHEAD.

Why do this? In short, it is an optimization for random read workloads such as OpenSearch.
See Phab tasks T264053 and T418776 for additional context.
"""

import json
import logging
import os
import re
import subprocess
import sys

TARGET_READAHEAD = 64
OS_DATA_PATH = "/usr/share/opensearch/data"

logger = logging.getLogger(__name__)


def setup_logging():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        stream=sys.stdout,
    )


def run(cmd, check=True):
    result = subprocess.run(
        cmd,
        check=check,
        capture_output=True,
        text=True,
        timeout=15,
    )
    return result.stdout.strip()


def get_opensearch_container_ids():
    """Return list of container IDs matching opensearch using JSON output."""
    raw = run(["crictl", "ps", "-o", "json"])
    data = json.loads(raw)

    containers = data.get("containers", [])
    matches = []

    for c in containers:
        name = c.get("metadata", {}).get("name", "")

        if "opensearch" in name.lower():
            pod_name = c.get("labels", {}).get("io.kubernetes.pod.name", "unknown")
            ctr_id = c.get("id")
            logger.info(
                "Found pod %s with container ID %s that could contain "
                "an OpenSearch datadir. Adding to list...", pod_name, ctr_id
            )
            matches.append(ctr_id)

    return matches


def get_mount_paths(container_id):
    """Given a container ID, check for a mount path matching our OS_DATA_PATH
    and return if a match is found"""

    raw = run(["crictl", "inspect", container_id])
    data = json.loads(raw)

    mounts = data.get("info", {}).get("config", {}).get("mounts", [])
    return [
        m.get("host_path")
        for m in mounts
        if m.get("container_path") == OS_DATA_PATH
    ]


def resolve_block_device(path):
    """Resolve backing block device using findmnt."""
    try:
        return run(["findmnt", "-T", path, "-no", "SOURCE"])
    except subprocess.CalledProcessError:
        return None


def extract_rbd(device):
    if not device:
        return None

    # Resolve symlinks (e.g., /dev/rbd/pool/vol -> /dev/rbd0)
    real_device = os.path.realpath(device)
    match = re.search(r"(rbd\d+)", real_device)
    return match.group(1) if match else None


def set_readahead(device, value):
    """Set block device readahead for OpenSearch datadir storage
    to TARGET_READAHEAD KB"""
    path = f"/sys/block/{device}/queue/read_ahead_kb"

    try:
        with open(path) as f:
            current = f.read().strip()

        if current == str(value):
            logger.info("%s read_ahead_kb already set to %s, not making changes...",
                        device, value)
            return

        with open(path, "w") as f:
            f.write(str(value))

        logger.info("Set %s read_ahead_kb -> %s", device, value)

    except Exception as e:
        logger.error("ERROR writing %s: %s", path, e)


def main():
    setup_logging()
    containers = get_opensearch_container_ids()
    if not containers:
        sys.exit(0)

    host_paths = set()
    for cid in containers:
        try:
            paths = get_mount_paths(cid)
        except Exception as e:
            logger.error("Failed to inspect container %s: %s", cid, e)
            continue
        logger.info("%s: %s", cid, paths)
        host_paths.update(p for p in paths if p)

    devices = set()
    for path in host_paths:
        src = resolve_block_device(path)
        logger.info("%s -> %s", path, src)
        rbd = extract_rbd(src)
        if rbd:
            devices.add(rbd)

    if not devices:
        sys.exit(0)

    logger.info("Detected RBD devices: %s", sorted(devices))

    for dev in devices:
        set_readahead(dev, TARGET_READAHEAD)


if __name__ == "__main__":
    main()
