#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-
#
# This file is part of Toolviews
#
# Copyright (C) 2018 Wikimedia Foundation and contributors
# All Rights Reserved.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
"""Collect Toolforge tool usage data from Nginx access logs and store in a
MySQL/MariaDB database for further analysis."""

from distutils.version import StrictVersion
import argparse
import collections
import datetime
import fileinput
import hashlib
import logging
import operator
from pathlib import Path
import re
import time

import ldap3
import pymysql
import yaml
from typing import Dict


logger = logging.getLogger("toolviews")

PROMETHEUS_FILE = Path("/var/lib/prometheus/node.d/toolviews.prom")


class StatHandler:
    def __init__(self):
        self.stats: Dict[str, list] = {}
        self.metric_prefix = "cloudvps.toolviews"

    def add_stat(self, stat_name: str, tool_name: str, stat_value: int) -> None:
        # For prometheus
        metric_name = f"{self.metric_prefix}.{stat_name}"
        if metric_name not in self.stats:
            self.stats[metric_name] = []
        self.stats[metric_name].append((tool_name, stat_value))
        logger.info(
            "%s => %f %s %d", metric_name, tool_name, stat_value, int(time.time())
        )

    def flush_stats(self) -> None:
        with PROMETHEUS_FILE.open("w", encoding="utf-8") as prom_fd:
            for metric_name, stats in self.stats.items():
                safe_metric_name = metric_name.replace(".", "_").replace("-", "_")
                prom_fd.write(f"# TYPE {safe_metric_name} counter\n")
                for stat in stats:
                    prom_fd.write(f'{safe_metric_name}{{tool="{stat[0]}"}} {stat[1]}\n')

        self.stats = {}


class ToolViews(object):
    RE_LINE = re.compile(
        r"(?P<vhost>[^ ]+) "
        r"(?P<ipaddr>[^ ]+) "
        r"(?P<ident>[^ ]+) "
        r"(?P<userid>[^ ]+) "
        r"\[(?P<datetime>[^\]]+) \+0000\] "
        r'"(?P<verb>[^ ]+) /(?P<tool>[^ /?]+)(?P<path>[^ ]*) HTTP/[^"]+" '
        r"(?P<status>\d+) "
        r"(?P<bytes>\d+) "
        r'"(?P<referer>[^"]*)" '
        r'"(?P<ua>[^"]*)"'
        r"(?P<extra>.*)"
    )

    UPSERT_SQL = (
        "INSERT INTO daily_raw_views (tool, request_day, hits) "
        "VALUES (%s, %s, %s) "
        "ON DUPLICATE KEY UPDATE hits=hits + VALUES(hits)"
    )

    INSERT_IP_SQL = (
        "INSERT IGNORE INTO daily_ip_views (tool, request_day, ip_hash) "
        "VALUES (%s, %s, %s) "
    )

    SELECT_PREVIOUS_DATES = (
        "SELECT DISTINCT(request_day) FROM daily_ip_views "
        "WHERE request_day < CURDATE()"
    )

    SELECT_TOOLS_BY_DATE = (
        "SELECT DISTINCT(tool) from daily_ip_views WHERE request_day = %s"
    )

    SELECT_DAILY_PAGEVIEWS = (
        "SELECT hits " "FROM daily_raw_views " "WHERE request_day = %s " "AND tool = %s"
    )

    SELECT_COUNT_DISTINCT_IPS = (
        "SELECT COUNT(DISTINCT(ip_hash)) "
        "FROM daily_ip_views "
        "WHERE request_day = %s "
        "AND tool = %s"
    )

    UPDATE_DAILY_UNIQUE_VIEWS = (
        "UPDATE daily_raw_views set uniqueiphits=%s "
        "WHERE request_day = %s "
        "AND TOOL = %s"
    )

    DELETE_DAILY_IPS = "DELETE FROM daily_ip_views WHERE request_day = %s "

    def __init__(self, config, dry_run):
        self.config = config
        self.dry_run = dry_run
        self.tools = self.get_tools()

    def get_tools(self):
        dn = "ou=servicegroups,{}".format(self.config["ldap"]["basedn"])
        conn = ldap3.Connection(
            self.config["ldap"]["servers"],
            user=self.config["ldap"]["user"],
            password=self.config["ldap"]["password"],
            auto_bind=True,
            auto_range=True,
            read_only=True,
        )
        try:
            groups = conn.extend.standard.paged_search(
                dn,
                "(&(objectclass=groupofnames)(cn=tools.*))",
                attributes=["cn"],
                time_limit=5,
                paged_size=256,
                generator=True,
            )
            return [group["attributes"]["cn"][0].split(".")[1] for group in groups]
        except Exception:
            logger.exception("Exception getting LDAP data for %s", dn)
        return []

    @staticmethod
    def field_map(dictseq, name, func):
        """Process a sequence of dictionaries and remap one of the fields.

        Typically used in a generator chain to coerce the datatype of
        a particular field. eg ``log = field_map(log, 'status', int)``

        Args:
            dictseq: Sequence of dictionaries
            name: Field to modify
            func: Modification to apply
        """
        for d in dictseq:
            if name in d:
                d[name] = func(d[name])
            yield d

    @staticmethod
    def format_date(d):
        """Convert log dates formatted as "29/Apr/2018:21:35:17" to
        standard iso date format truncated to the day.

        Args:
            d: date string to reformat
        Returns:
            ISO 8601 formatted date (YYYY-MM-DD)
        """
        return datetime.datetime.strptime(d, "%d/%b/%Y:%H:%M:%S").strftime("%Y-%m-%d")

    @staticmethod
    def parse_log(lines, logpat):
        """Parse a log file into a sequence of dicts.

        Args:
            lines: line generator
            logpat: regex to split lines
        Returns:
            generator of mapped lines
        """
        groups = (logpat.match(line) for line in lines)
        tuples = (g.groupdict() for g in groups if g)
        log = ToolViews.field_map(tuples, "datetime", ToolViews.format_date)
        log = ToolViews.field_map(log, "status", int)
        return log

    @staticmethod
    def split_list(the_list, size):
        """Yield successive sub-lists of a given list."""
        for i in range(0, len(the_list), size):
            yield the_list[i:i + size]

    def run(self, files):
        # Count rows per tool per day
        stats = collections.defaultdict(lambda: collections.defaultdict(list))
        salt = self.config["ip_hash_salt"].encode()
        for r in ToolViews.parse_log(fileinput.input(files=files), self.RE_LINE):
            if 200 <= r["status"] < 300:
                # Status codes of 200 to 299 are 'success' codes.
                # We don't care about client or server errors or redirects

                if r["vhost"] == "tools.wmflabs.org":
                    # Path based routing (legacy)
                    # FIXME: add support for toolsbeta?
                    tool = r["tool"]
                else:
                    # Host based routing
                    tool = r["vhost"].split(".")[0]

                if tool not in self.tools:
                    if tool not in (".well-known", "index.php", "robots.txt"):
                        logger.info('Unknown tool "%s"', tool)
                    # fourohfour is the default route handler
                    tool = "fourohfour"
                stats[tool][r["datetime"]].append(r["ipaddr"])

        rows = []
        urows = []
        stat_handler = StatHandler()

        for tool, days in stats.items():
            if self.dry_run:
                count = 0
                for day in days:
                    count += len(days[day])
                print("{}: {}".format(tool, count))
            for day, hits in days.items():
                rows.append((tool, day, len(hits)))
                # The set() magic here ensures only one entry per ip
                for ip in set(hits):
                    # Out of an excess of caution, hash ip address before storing.
                    # We only care about uniqueness, not the IP itself. Best practice
                    #  is 100,000 iterations but we need this to finish before the
                    #  next log rotation!
                    hashed_ip = hashlib.pbkdf2_hmac("sha256", ip.encode(), salt, 100)
                    urows.append((tool, day, hashed_ip))

        if not self.dry_run:
            dbh = pymysql.connect(
                host=self.config["mysql_host"],
                user=self.config["mysql_user"],
                password=self.config["mysql_password"],
                database=self.config["mysql_db"],
                charset="utf8",
                cursorclass=pymysql.cursors.DictCursor,
                autocommit=False,
            )
            # Sort rows by date & tool
            rows.sort(key=operator.itemgetter(1, 0))
            try:
                with dbh.cursor() as cursor:
                    for chunk in ToolViews.split_list(rows, 500):
                        try:
                            cursor.executemany(self.UPSERT_SQL, chunk)
                            dbh.commit()
                        except pymysql.MySQLError:
                            logger.exeception("Failed to insert rows")
                            dbh.rollback()
                    for chunk in ToolViews.split_list(urows, 500):
                        try:
                            cursor.executemany(self.INSERT_IP_SQL, chunk)
                            dbh.commit()
                        except pymysql.MySQLError:
                            logger.exeception("Failed to insert rows")
                            dbh.rollback()

                    # Now count up unique hits for previous days and then clean up old records
                    #  in daily_ip_views.

                    # Most runs this will return 0 records; once per day
                    #  it should return one record.
                    cursor.execute(self.SELECT_PREVIOUS_DATES)
                    olddays = cursor.fetchall()
                    for oldday in olddays:
                        cursor.execute(
                            self.SELECT_TOOLS_BY_DATE, (oldday["request_day"],)
                        )
                        tools = cursor.fetchall()
                        for tool in tools:
                            toolname = tool["tool"]
                            # Collect the daily total views for prometheus
                            cursor.execute(
                                self.SELECT_DAILY_PAGEVIEWS,
                                (oldday["request_day"], toolname),
                            )
                            dailyhits = cursor.fetchone()
                            if dailyhits:
                                stat_handler.add_stat(
                                    "daily_views", toolname, dailyhits["hits"]
                                )

                            cursor.execute(
                                self.SELECT_COUNT_DISTINCT_IPS,
                                (oldday["request_day"], toolname),
                            )
                            uniquehits = cursor.fetchone()["COUNT(DISTINCT(ip_hash))"]
                            stat_handler.add_stat(
                                "daily_unique_views", toolname, uniquehits
                            )
                            cursor.execute(
                                self.UPDATE_DAILY_UNIQUE_VIEWS,
                                (uniquehits, oldday["request_day"], toolname),
                            )
                            dbh.commit()

                        cursor.execute(self.DELETE_DAILY_IPS, (oldday["request_day"],))
                        dbh.commit()

            finally:
                dbh.close()
                stat_handler.flush_stats()


def main():
    # T237080: Verify that the version of ldap3 is new enough
    if StrictVersion(ldap3.__version__) < StrictVersion("1.2.2"):
        raise AssertionError(
            "toolviews needs ldap3>=1.2.2, found {}".format(ldap3.__version__)
        )

    parser = argparse.ArgumentParser(description="Load tool analytics into database")
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        dest="loglevel",
        help="Increase logging verbosity",
    )
    parser.add_argument(
        "--config", default="/etc/toolviews.yaml", help="Path to YAML config file"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse logs but output to screen instead of database",
    )
    parser.add_argument(
        "files",
        metavar="FILE",
        nargs="*",
        help="Access logs to read. If empty, stdin is used",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
        format="%(asctime)s %(name)-12s %(levelname)-8s: %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%SZ",
    )
    logging.captureWarnings(True)

    with open(args.config) as f:
        config = yaml.safe_load(f)

    with open(config.get("ldap_config", "/etc/ldap.yaml")) as f:
        config["ldap"] = yaml.safe_load(f)

    stats = ToolViews(config, args.dry_run)
    stats.run(args.files)


if __name__ == "__main__":
    main()
