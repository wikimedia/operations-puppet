#! /usr/bin/python3
# -*- coding: utf-8 -*-
"""
Get a list of currently running queries in the wikireplicas and store them for
later retrieval. Optionally, do this at random intervals as a service.
"""
from __future__ import annotations

import argparse
import json
import logging
import sqlite3
import time
from contextlib import closing
from datetime import datetime
from random import randrange
from typing import Any

import pymysql

# xlsxwriter does not provide types
import xlsxwriter  # type: ignore
import yaml

PROC_QUERY = """
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE command = 'Query'
and user <> 'querysampler';
"""


def parse_args() -> argparse.Namespace:
    # Parse the CLI
    parser = argparse.ArgumentParser(
        description="contact the wikireplicas and store the gathered queries"
    )
    parser.add_argument(
        "-c",
        dest="config",
        metavar="<configuration_file>",
        help="location of the configuration file (YAML)",
        default="/etc/querysampler-config.yaml",
    )
    parser.add_argument(
        "--mysql-socket",
        help="Path to MySQL socket file",
        default="/run/mysqld/mysqld.sock",
    )
    parser.add_argument(
        "-d",
        "--daemonize",
        help="Run as a service rather than a one-shot",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--dump",
        help="dump out the contents of the local DB into a JSON file for analysis",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--xlsx",
        help="Is NOOP unless dumping. Dump as an Excel spreadsheet instead of JSON",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="Print out things only",
    )
    return parser.parse_args()


def query_replicas(config: dict, dry_run: bool) -> list:
    queries = []
    for host in config["hosts"]:
        repl_config = {"host": host, "user": config["user"], "password": config["password"]}
        queries.extend(get_queries(repl_config, dry_run))

    return queries


def get_queries(config, dry_run):
    if dry_run:
        logging.info("I would run %s on %s", PROC_QUERY, config["host"])
        return []
    output = []
    with closing(
        pymysql.connect(
            user=config["user"],
            passwd=config["password"],
            host=config["host"],
            charset="utf8",
        )
    ) as connection:
        with connection.cursor() as cur:
            cur.execute(PROC_QUERY)
            raw_output = cur.fetchall()
            cur.execute("select @@hostname;")
            host = cur.fetchone()
            if raw_output and host:
                for row in raw_output:
                    output.append([host[0], row[1], row[3], row[7]])

    return output


def save_queries(db_location: str, queries: list):
    with closing(sqlite3.connect(db_location)) as connection:
        with closing(connection.cursor()) as cursor:
            sql = """
                INSERT INTO query_reports(host,user,db,query,date,time)
                VALUES (?, ?, ?, ?, ?, ?);
            """
            today = datetime.utcnow().date().isoformat()
            now = datetime.utcnow().time().isoformat()
            for query in queries:
                query.append(today)
                query.append(now)
                cursor.execute(sql, query)
            connection.commit()


def dump_queries(db_location: str, xlsx: bool):
    with closing(sqlite3.connect(db_location)) as connection:
        with closing(connection.cursor()) as cursor:
            statement = cursor.execute("SELECT * FROM query_reports;")
            headers = cursor.description
            if xlsx:
                with xlsxwriter.Workbook("querysampler.xlsx") as workbook:
                    worksheet = workbook.add_worksheet()
                    # Who doesn't like headers?
                    for x, h in enumerate(headers):
                        worksheet.write(0, x, h[0])
                    for i, row in enumerate(statement, start=1):
                        for j, value in enumerate(row):
                            worksheet.write(i, j, value)
            else:
                # Hope you have your shell redirected. Open wide!
                print("[", end="")
                for i, row in enumerate(statement):
                    row_dict = {}
                    for j, value in enumerate(row):
                        row_dict[headers[j][0]] = value
                    if i > 0:
                        print("," + json.dumps(row_dict), end="")
                    else:
                        print(json.dumps(row_dict), end="")
                print("]")


def load_config(path) -> dict[str, Any]:
    with open(path) as conf_file:
        try:
            config = yaml.safe_load(conf_file)
        except yaml.YAMLError:
            logging.exception("YAML file at %s could not be opened", path)
            raise
    return config


def main():
    args = parse_args()
    config = load_config(args.config)

    if args.dump:
        dump_queries(config["localdb"], args.xlsx)
        return

    if not args.daemonize:
        q = query_replicas(config, args.dry_run)
        if not args.dry_run:
            save_queries(config["localdb"], q)

        return

    while True:
        q = query_replicas(config, args.dry_run)
        if not args.dry_run:
            save_queries(config["localdb"], q)

        time.sleep(randrange(10, 4000))


if __name__ == "__main__":
    main()
