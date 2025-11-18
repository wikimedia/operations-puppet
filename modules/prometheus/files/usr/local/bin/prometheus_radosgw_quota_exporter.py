#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import logging
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

import click
import yaml

logger = logging.getLogger(__name__)


PROM_HEADER = """
# HELP ceph_rgw_quota_size_kb_used Number of kilobytes used by the user
# TYPE ceph_rgw_quota_size_kb_used gauge
# HELP ceph_rgw_quota_size_kb_total Maximum kilobytes available for the user
# TYPE ceph_rgw_quota_size_kb_total gauge
# HELP ceph_rgw_quota_size_objects_used Number of objects used by the user
# TYPE ceph_rgw_quota_size_objects_used gauge
# HELP ceph_rgw_quota_size_objects_total Maximum objects available for the user
# TYPE ceph_rgw_quota_size_objects_total gauge
"""


def get_users() -> list[str]:
    return yaml.safe_load(subprocess.check_output(["radosgw-admin", "user", "list"]))


def get_user_info(user: str) -> dict[str, Any]:
    return yaml.safe_load(
        subprocess.check_output(["radosgw-admin", "user", "info", "--uid", user])
    )


def get_quota(user: str) -> dict[str, Any]:
    return yaml.safe_load(
        subprocess.check_output(["radosgw-admin", "user", "stats", "--uid", user])
    )


@click.command()
@click.option(
    "--prom-file", type=Path, default="/var/lib/prometheus/node.d/rgw_quota_stats.prom"
)
def main(prom_file: Path):
    users = get_users()
    _, temp_file = tempfile.mkstemp(dir=prom_file.parent)
    with open(temp_file, "w") as prom_fd:
        prom_fd.write(PROM_HEADER)
        for user in users:
            try:
                user_info = get_user_info(user=user)
            except Exception as error:
                logger.exception(
                    f"Unable to get info for user {user}, skipping: {error}"
                )
                continue

            try:
                # this one will fail if the user does not use object storage
                quota = get_quota(user=user)
            except Exception as error:
                logger.exception(
                    f"Unable to get quota for user {user}, skipping: {error}"
                )
                continue

            user_name = user_info["display_name"]
            size_kb = quota["stats"]["size_kb"]
            size_kb_total = user_info["user_quota"]["max_size_kb"]
            objects = quota["stats"]["num_objects"]
            objects_total = user_info["user_quota"]["max_objects"]
            prom_fd.write(
                f'ceph_rgw_quota_size_kb_used{{user="{user_name}"}} {size_kb}\n'
            )
            prom_fd.write(
                f'ceph_rgw_quota_size_kb_total{{user="{user_name}"}} {size_kb_total}\n'
            )
            prom_fd.write(
                f'ceph_rgw_quota_objects_used{{user="{user_name}"}} {objects}\n'
            )
            prom_fd.write(
                f'ceph_rgw_quota_objects_total{{user="{user_name}"}} {objects_total}\n'
            )

    shutil.move(temp_file, prom_file)


if __name__ == "__main__":
    main()
