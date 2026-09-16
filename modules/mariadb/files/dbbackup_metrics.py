#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Extracts multi-dimensional backup metrics from `dbbackups.backups`
- dbbackups_last_backup_time_seconds
- dbbackups_last_backup_duration_seconds
- dbbackups_last_backup_bytes

Runs locally on m1 hosts. Metrics from different m1 hosts are then
deduplicated on Grafana, providing rudimentary redundancy.
"""

import logging
import os
import pymysql
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile

# Ignore sections that have never been backed up after this unix timestamp
TIME_THRESHOLD_TS: int | None = None

# Runs only on multiinstance hosts, see dbbackup_metrics.pp
SOCK = "/run/mysqld/mysqld.m1.sock"

log = logging.getLogger()

registry = CollectorRegistry()

gauge_age = Gauge(
    "dbbackups_last_backup_time_seconds",
    "Timestamp of last successful backup completed",
    ["section", "type"],
    registry=registry,
)
gauge_duration = Gauge(
    "dbbackups_last_backup_duration_seconds",
    "Duration of the last successful backup in seconds",
    ["section", "type"],
    registry=registry,
)
gauge_size = Gauge(
    "dbbackups_last_backup_bytes",
    "Total size of the last successful backup in bytes",
    ["section", "type"],
    registry=registry,
)


def main() -> None:
    logging.basicConfig(level=logging.DEBUG, format="%(message)s")
    log.info("[dbbackup_metrics] starting")
    if not os.path.exists(SOCK):
        log.info(f"[dbbackup_metrics] {SOCK} not present: exiting")
        return

    conn = pymysql.connect(
        unix_socket=SOCK,
        user="root",
        database="dbbackups",
        cursorclass=pymysql.cursors.DictCursor,
    )

    with conn.cursor() as cursor:
        query = """
            SELECT
                section,
                type,
                total_size,
                TIMESTAMPDIFF(SECOND, start_date, end_date) AS duration_seconds,
                UNIX_TIMESTAMP(end_date) AS end_ts_seconds
            FROM dbbackups.backups
            WHERE id IN (
                SELECT MAX(id)
                FROM dbbackups.backups
                WHERE status = 'finished'
                GROUP BY section, type
            );
        """
        cursor.execute(query)
        rows = cursor.fetchall()

    log.info("[dbbackup_metrics] fetched %d rows", len(rows))
    for r in rows:
        section = r["section"]
        bk_type = r["type"]
        age = r["end_ts_seconds"]
        duration = r["duration_seconds"]
        size = r["total_size"]

        if TIME_THRESHOLD_TS and age < TIME_THRESHOLD_TS:
            continue

        gauge_age.labels(section=section, type=bk_type).set(age)
        gauge_duration.labels(section=section, type=bk_type).set(duration)
        gauge_size.labels(section=section, type=bk_type).set(size)

    write_to_textfile("/var/lib/prometheus/node.d/dbbackups.prom", registry)
    log.info("[dbbackup_metrics] run completed")


if __name__ == "__main__":
    main()
