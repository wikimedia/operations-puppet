#!/usr/bin/env python3
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

import argparse
import collections
import datetime
import fileinput
import logging
import operator
import re

import ldap3
import pymysql
import yaml


logger = logging.getLogger('toolviews')


class ToolViews(object):
    RE_LINE = re.compile(
        r'(?P<vhost>[^ ]+) '
        r'(?P<ipaddr>[^ ]+) '
        r'(?P<ident>[^ ]+) '
        r'(?P<userid>[^ ]+) '
        r'\[(?P<datetime>[^\]]+) \+0000\] '
        r'"(?P<verb>[^ ]+) /(?P<tool>[^ /?]+)(?P<path>[^ ]*) HTTP/[^"]+" '
        r'(?P<status>\d+) '
        r'(?P<bytes>\d+) '
        r'"(?P<referer>[^"]*)" '
        r'"(?P<ua>[^"]*)"'
    )

    UPSERT_SQL = (
        "INSERT INTO daily_raw_views (tool, request_day, hits) "
        "VALUES (%s, %s, %s) "
        "ON DUPLICATE KEY UPDATE hits=hits + VALUES(hits)"
    )

    def __init__(self, config, dry_run):
        self.config = config
        self.dry_run = dry_run
        self.tools = self.get_tools()

    def get_tools(self):
        dn = 'ou=servicegroups,{}'.format(self.config['ldap']['basedn'])
        conn = ldap3.Connection(
            ldap3.ServerPool([
                ldap3.Server(s)
                for s in self.config['ldap']['servers']
            ], ldap3.POOLING_STRATEGY_ROUND_ROBIN, active=True, exhaust=True),
            read_only=True,
            user=self.config['ldap']['user'],
            auto_bind=True,
            password=self.config['ldap']['password'])

        groups = []
        try:
            conn.search(
                dn,
                '(&(objectclass=groupofnames)(cn=tools.*))',
                ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
                attributes=['cn'],
                time_limit=5,
                paged_size=256,
            )
            for resp in conn.response:
                groups.append(resp['attributes']['cn'][0].split('.')[1])

            cookie = conn.result['controls']['1.2.840.113556.1.4.319']['value']['cookie']
            while cookie:
                conn.search(
                    dn,
                    '(&(objectclass=groupofnames)(cn=tools.*))',
                    ldap3.SEARCH_SCOPE_WHOLE_SUBTREE,
                    attributes=['cn'],
                    time_limit=5,
                    paged_size=256,
                    paged_cookie=cookie,
                )
                cookie = conn.result['controls']['1.2.840.113556.1.4.319']['value']['cookie']
                for resp in conn.response:
                    groups.append(resp['attributes']['cn'][0].split('.')[1])
        except Exception:
            logger.exception('Exception getting LDAP data for %s', dn)
        return groups

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
        return datetime.datetime.strptime(
            d, '%d/%b/%Y:%H:%M:%S').strftime('%Y-%m-%d')

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
        log = ToolViews.field_map(tuples, 'datetime', ToolViews.format_date)
        log = ToolViews.field_map(log, 'status', int)
        return log

    @staticmethod
    def split_list(l, size):
        """Yield successive sub-lists of a given list."""
        for i in range(0, len(l), size):
            yield l[i:i + size]

    def run(self, files):
        # Count rows per tool per day
        stats = collections.defaultdict(lambda: collections.defaultdict(int))
        for r in ToolViews.parse_log(
            fileinput.input(files=files), self.RE_LINE
        ):
            if 200 <= r['status'] < 300:
                # Status codes of 200 to 299 are 'success' codes.
                # We don't care about client or server errors
                tool = r['tool']
                if r['tool'] not in self.tools:
                    if tool not in ('.well-known', 'index.php', 'robots.txt'):
                        logger.info('Unknown tool "%s"', tool)
                    tool = 'admin'
                stats[tool][r['datetime']] += 1

        rows = []
        for tool, days in stats.items():
            if self.dry_run:
                print('{}: {}'.format(tool, sum(days.values())))
            for day, hits in days.items():
                rows.append((tool, day, hits))

        if not self.dry_run:
            dbh = pymysql.connect(
                host=self.config['mysql_host'],
                user=self.config['mysql_user'],
                password=self.config['mysql_password'],
                database=self.config['mysql_db'],
                charset='utf8',
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
                            logger.exeception('Failed to insert rows')
                            dbh.rollback()
            finally:
                dbh.close()


def main():
    parser = argparse.ArgumentParser(
        description='Load tool analytics into database')
    parser.add_argument(
        '-v', '--verbose', action='count', default=0, dest='loglevel',
        help='Increase logging verbosity')
    parser.add_argument(
        '--config', default='/etc/toolviews.yaml',
        help='Path to YAML config file')
    parser.add_argument(
        '--dry-run', action='store_true',
        help='Parse logs but output to screen instead of database')
    parser.add_argument(
        'files', metavar='FILE', nargs='*',
        help='Access logs to read. If empty, stdin is used')
    args = parser.parse_args()

    logging.basicConfig(
        level=max(logging.DEBUG, logging.WARNING - (10 * args.loglevel)),
        format='%(asctime)s %(name)-12s %(levelname)-8s: %(message)s',
        datefmt='%Y-%m-%dT%H:%M:%SZ')
    logging.captureWarnings(True)

    with open(args.config) as f:
        config = yaml.safe_load(f)

    with open(config.get('ldap_config', '/etc/ldap.yaml')) as f:
        config['ldap'] = yaml.safe_load(f)

    stats = ToolViews(config, args.dry_run)
    stats.run(args.files)


if __name__ == '__main__':
    main()
