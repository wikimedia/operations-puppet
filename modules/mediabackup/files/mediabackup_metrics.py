#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Extracts multi-dimensional backup metrics from `mediabackups.files`
- mediabackups_worker_queue
Runs locally on mediabackup workers.
"""

import logging

import pymysql
from prometheus_client import (
    CollectorRegistry,
    Gauge,
    write_to_textfile,
)

# Ignore sections that have never been backed up after this unix timestamp
TIME_THRESHOLD_TS: int | None = None

# Runs on ms-backup instances
log = logging.getLogger()

# Gauges
registry = CollectorRegistry()
gauge_worker_queue = Gauge(
    name="mediabackups_worker_queue",
    documentation="Queue status totals for the past hour",
    labelnames=["status"],
    registry=registry,
)
gauge_worker_backup = Gauge(
    name="mediabackups_worker_backup",
    documentation="Total backups by location for the past hour",
    labelnames=["location"],
    registry=registry,
)


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    log.info("[mediabackup_metrics] starting")

    conn = pymysql.connect(
        read_default_file="/etc/mediabackup/mediabackups_db.ini",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False,
        read_timeout=300,
        init_command="SET SESSION tx_isolation = 'REPEATABLE-READ'",
    )

    backup_status_result: tuple = ()
    queue_status_result: tuple = ()

    log.debug("[mediabackup_metrics] starting transaction")
    conn.begin()

    with conn.cursor() as cursor:
        sql_queue_status = """
        SELECT
            backup_status.backup_status_name AS status,
            COUNT(1) AS total
        FROM files
        INNER JOIN backup_status ON backup_status.id = files.backup_status
        WHERE files.upload_timestamp >= NOW() - INTERVAL 1 HOUR
        GROUP BY backup_status.id
        """

        sql_backup_status_by_location = """
        SELECT
            (select locations.location_name from locations
             where locations.id = location limit 1) AS location,
            COUNT(1) AS total
        FROM backups
        WHERE backups.backup_time >= NOW() - INTERVAL 1 HOUR
        GROUP BY backups.location
        """

        log.debug("[mediabackup_metrics] querying queue_status")
        if cursor.execute(sql_queue_status):
            queue_status_result = cursor.fetchall()
            log.debug("[mediabackup_metrics] fetched %d rows for queue_status",
                      len(queue_status_result))
        else:
            log.error("[mediabackup_metrics] Failed to gather results for the queue")

        log.debug("[mediabackup_metrics] querying backup_status")
        if cursor.execute(sql_backup_status_by_location):
            backup_status_result = cursor.fetchall()
            log.debug("[mediabackup_metrics] fetched %d rows for backup_status",
                      len(backup_status_result))
        else:
            log.error("[mediabackup_metrics] Failed to gather results for the backups")

    log.debug("[mediabackup_metrics] rolling back transaction")
    conn.rollback()
    log.debug("[mediabackup_metrics] closing connection")
    conn.close()

    for backup in backup_status_result:
        location = (backup["location"].decode()
                    if isinstance(backup["location"], bytes) else backup["location"])
        log.debug("[mediabackup_metrics] %d files sent to %s", backup["total"], location)
        gauge_worker_backup.labels(location=location).set(backup["total"])

    for queue in queue_status_result:
        status = queue["status"].decode() if isinstance(queue["status"], bytes) else queue["status"]
        log.debug("[mediabackup_metrics] %d files in state %s", queue["total"], status)
        gauge_worker_queue.labels(status=status).set(queue["total"])

    write_to_textfile("/var/lib/prometheus/node.d/mediabackups.prom", registry)
    log.info("[mediabackup_metrics] run completed")


if __name__ == "__main__":
    main()
