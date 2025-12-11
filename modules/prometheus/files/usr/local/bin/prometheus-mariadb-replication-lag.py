#!/usr/bin/env python3
# Copyright 2025 Federico Ceratto <fceratto@wikimedia.org>
#                Wikimedia Foundation
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Generates mysql_heartbeat_lag_seconds Prometheus metric
- ignores stale rows in the heartbeat.heartbeat table caused by primary switchover
  or past configuration
- includes the replication primary hostname
- avoids sub-second sampling noise

Related to T384810
"""

import logging
import pymysql
import socket
import time
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile


SCRAPE_INTERVAL = 30.0
SOCK = "/run/mysqld/mysqld.sock"
PROM_FN = "/var/lib/prometheus/node.d/heartbeat_lag.prom"

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)

# Ignore local heartbeat row, select most recent heartbeat
hostname = socket.gethostname()
SQL = f"""
SELECT TIMESTAMPDIFF(SECOND, ts, NOW()) AS lag, file, server_id, shard
FROM heartbeat.heartbeat
WHERE file NOT LIKE '{hostname}-bin%'
ORDER BY ts DESC
LIMIT 1
"""


def probe(cursor) -> None:
    cursor.execute(SQL)
    row = cursor.fetchone()
    if not row:
        # The script could be running on primary source.
        return

    lag, replfile, server_id, section = row

    if isinstance(replfile, bytes):
        replfile = replfile.decode()
    if isinstance(section, bytes):
        section = section.decode()

    # e.g. db1176-bin.000390
    primary_hn = replfile.split("-", 1)[0]

    # Create a new gauge on the fly to prevent stale values
    registry = CollectorRegistry()
    lag_gauge = Gauge(
        "mysql_heartbeat_lag_seconds",
        "Lag of MySQL replication heartbeat in seconds",
        ["server_id", "primary", "shard"],
        registry=registry,
    )
    lag_gauge.labels(server_id=str(server_id), primary=primary_hn, shard=section).set(lag)
    write_to_textfile(PROM_FN, registry)


def main() -> None:
    next_run_t = time.time()
    while True:
        try:
            with pymysql.connect(unix_socket=SOCK, database="heartbeat", autocommit=True) as conn:
                with conn.cursor() as cursor:
                    probe(cursor)
        except Exception as e:
            log.error(f"Error: {e}, reconnecting...")

        next_run_t += SCRAPE_INTERVAL  # no drifting
        sleep_time = max(0, next_run_t - time.time())
        time.sleep(sleep_time)


if __name__ == "__main__":
    main()
