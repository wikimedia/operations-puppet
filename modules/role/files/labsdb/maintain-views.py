#! /usr/bin/python3
# -*- coding: utf-8 -*-

#  Based on work by Marc-André Pelletier, ported to Python by Alex Monk
#  Copyright © 2016 Alex Monk <alex@wikimedia.org>
#  Copyright © 2015 Alex Monk <krenair@gmail.com>
#  Copyright © 2013 Marc-André Pelletier <mpelletier@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
#  This script maintains the databases containing sanitized views to
#  the replicated databases (in the form <db>_p for every <db>)
#
#  By default, it processes every database but it accepts a list of
#  databases to process
#
#  Information on available and operational databases is sourced from
#  a checkout of mediawiki-config.
#

import argparse
import json
import logging
import re

import pymysql


class SchemaOperations():
    def __init__(self, dry_run, replace_all, db, db_size, cursor):
        self.dry_run = dry_run
        self.replace_all = replace_all
        self.db = db
        self.db_p = db + '_p'
        self.db_size = db_size
        self.cursor = cursor

    def write_execute(self, query):
        if self.dry_run:
            logging.info("DRY RUN: Would execute: {}".format(query))
        else:
            self.cursor.execute(query)

    def table_exists(self, table, database):
        """
        Determine whether a table of the given name exists in the database of
        the given name.
        """
        self.cursor.execute("""
            SELECT `table_name`
            FROM `information_schema`.`tables`
            WHERE `table_name`=%s AND `table_schema`=%s;
        """, args=(table, database))
        return bool(self.cursor.rowcount)

    def execute(self, fullviews, customviews):
        """
        Begin checking/creating views for this schema.
        """

        self.cursor.execute("""
            SELECT `schema_name`
            FROM `information_schema`.`schemata`
            WHERE `schema_name`=%s
        """, args=(self.db_p,))
        if not self.cursor.rowcount:
            # Can't use pymysql to build this
            self.write_execute(
                "CREATE DATABASE `{}`;".format(self.db_p)
            )

        logging.info("Full views for {}:".format(self.db))
        for view in fullviews:
            self.do_fullview(view)

        logging.info("Custom views for {}:".format(self.db))
        for view_name, view_details in customviews.items():
            self.do_customview(view_name, view_details)

    def do_fullview(self, view):
        """
        Check whether the source table exists, and if so, create the view.
        """
        if self.table_exists(view, self.db):
            # If it does, create or replace the view for it.
            logging.info("[{}] ".format(view))
            if (self.replace_all or not self.table_exists(view, self.db_p) or
                    input('View already exists. Replace? [y/N] ').lower()
                    in ['y', 'yes']):
                # Can't use pymysql to build this
                self.write_execute("""
                    CREATE OR REPLACE
                    DEFINER=viewmaster
                    VIEW `{0}`.`{1}`
                    AS SELECT * FROM `{2}`.`{1}`;
                """.format(self.db_p, view, self.db))
        else:
            # Some views only exist in CentralAuth, some only in MediaWiki,
            # etc.
            logging.debug(
                ("Skipping full view {} on database {} as the table does not"
                    " seem to exist.")
                .format(view, self.db)
            )

    def check_customview_source(self, view_name, source):
        """
        Check whether a custom view's particular source exists. If it does,
        return the source database and table names. If not, return False.
        """
        match = re.match(r"^(?:(.*)\.)?([^.]+)$", source)
        if not match:
            raise Exception(
                "Custom view source does not look valid! Source: {}, view: {}"
                .format(source, view_name)
            )

        # Effectively separate a db.table source into it's parts
        source_db, source_table = match.groups()

        # If there was no DB part, assume the current DB name
        if source_db is None:
            source_db = self.db

        if self.table_exists(source_table, source_db):
            # If it does, take this source into account.
            return source_db, source_table
        else:
            logging.debug(
                ("Failed to find table {} in database {} as a source for"
                    " view {}")
                .format(source_table, source_db, view_name)
            )
            return False

    def do_customview(self, view_name, view_details):
        """
        Process a custom view's sources, and if they're all present, and the
        view's limit is not bigger than the database size, call
        create_customview.
        """
        if ("limit" in view_details and self.db_size is not None and
                view_details["limit"] > self.db_size):
            # Ignore custom views which have a limit number greater
            # than the size ID set by the read_list calls for
            # size.dblist above.
            logging.debug("Too big for this database")
            return

        sources = view_details["source"]
        if sources.__class__ is str:
            sources = [sources]

        sources_checked = []

        for source in sources:
            result = self.check_customview_source(view_name, source)
            if result:
                source_db, source_table = result
                sources_checked.append(
                    "`{}`.`{}`".format(source_db, source_table)
                )
            else:
                break

        if len(sources) == len(sources_checked):

            if (self.replace_all or
                    not self.table_exists(view_name, self.db_p) or
                    input('View already exists. Replace? [y/N] ').lower()
                    in ['y', 'yes']):
                logging.info("[{}] ".format(view_name))
                self.create_customview(
                    view_name,
                    view_details,
                    sources_checked
                )
        else:
            # If any source was not found, ignore this view.
            # Some views only exist in CentralAuth, some only in MediaWiki,
            # etc.
            logging.debug(
                ("Skipping custom view {} on database {} as not all sources"
                    " were verified.\nSources: {}\nVerified sources: {}")
                .format(
                    view_name,
                    self.db,
                    str(view_details["source"]),
                    str(sources_checked)
                )
            )

    def create_customview(self, view_name, view_details, sources):
        """
        Creates or replaces a custom view from it's sources.
        """
        query = """
            CREATE OR REPLACE
            DEFINER=viewmaster
            VIEW `{}`.`{}`
            AS {}
            FROM {}
        """.format(
            self.db_p,
            view_name,
            view_details["view"],
            ",".join(sources)
        )

        if "where" in view_details:
            query += " WHERE {}\n".format(view_details["where"])
        if "group" in view_details:
            # Technically nothing is using this at the moment...
            query += " GROUP BY {}\n".format(view_details["group"])

        query += ";"

        # Can't use pymysql to build this
        self.write_execute(query)


def do_dbhost(dry_run, replace_all, dbhost, dbport, config, dbs, customviews):
    """
    Handle setting up a connection to a dbhost, then go through every database
    to start the process of creating views there.
    """
    dbh = pymysql.connect(
        host=dbhost,
        port=dbport,
        user=config["mysql_user"],
        passwd=config["mysql_password"],
        charset="utf8"
    )
    with dbh.cursor() as cursor:
        logging.info("Connected to {}:{}...".format(dbhost, dbport))
        cursor.execute("SET NAMES 'utf8';")
        for db, db_info in dbs.items():
            skip = False
            for bad_flag in ["deleted", "private"]:
                if db_info.get(bad_flag, False):
                    logging.debug(
                        "Skipping database {} because it's marked as {}."
                        .format(db, bad_flag)
                    )
                    skip = True

            if skip:
                continue

            db_size = None
            if "size" in db_info:
                db_size = db_info["size"]

            ops = SchemaOperations(dry_run, replace_all, db, db_size, cursor)
            ops.execute(config["fullviews"], customviews)

if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)

    argparser = argparse.ArgumentParser(
        "maintain-views",
        description="Maintain labs sanitized views of replica databases"
    )
    argparser.add_argument(
        "--config-location",
        help="Path to find the configuration file",
        default="/etc/maintain-views.json"
    )
    argparser.add_argument(
        "--dry-run",
        help=("Give this parameter if you don't want the script to actually"
              " make changes."),
        action="store_true"
    )
    argparser.add_argument(
        "--replace-all",
        help=("Give this parameter if you don't want the script to prompt"
              " before replacing views."),
        action="store_true"
    )
    argparser.add_argument(
        "--databases",
        help=("Specify database(s) to work on, instead of all. Multiple"
              " values can be given space-separated."),
        nargs="+"
    )
    argparser.add_argument(
        "--mediawiki-config",
        help=("Specify path to mediawiki-config checkout"
              " values can be given space-separated."),
        default="/usr/local/lib/mediawiki-config"
    )
    args = argparser.parse_args()
    with open(args.config_location) as f:
        config = json.load(f)

    # Hacks
    safelog = ("log_type IN ('" +
               "', '".join(config["logging_whitelist"]) +
               "')")
    customviews = config["customviews"]
    customviews["logging"]["where"] = safelog
    customviews["logging_logindex"]["where"] = ("(log_deleted&1)=0 and " +
                                                safelog)
    customviews["logging_userindex"]["where"] = ("(log_deleted&4)=0 and " +
                                                 safelog)

    with open("{}/dblists/all.dblist".format(args.mediawiki_config)) as f:
        all_available_dbs = f.read().splitlines()

    all_available_dbs.append("centralauth")
    if args.databases:
        dbs = {}
        for db in args.databases:
            if db in all_available_dbs:
                dbs[db] = {}
            else:
                logging.info(
                    "Ignoring database {} which doesn't appear to exist."
                    .format(db)
                )

        if not len(dbs.keys()):
            logging.critical("No databases specified exist.")
    else:
        dbs = {db: {} for db in all_available_dbs}

    def read_list(fname, prop, val):
        with open("{}/dblists/{}.dblist".format(args.mediawiki_config, fname)) as f:
            for db in f.read().splitlines():
                if db in dbs:
                    dbs[db][prop] = val

    # Reads various .dblist files to store information about specific
    # databases. The first line, for example, reads deleted.dblist, and for
    # each listed database name sets dbs[db_name]["deleted"] = True
    read_list("deleted", "deleted", True)
    read_list("private", "private", True)
    read_list("small", "size", 1)
    read_list("medium", "size", 2)
    read_list("large", "size", 3)

    logging.info("Got all necessary info, starting to connect to slices")
    for dbhost, dbport in config["slices"]:
        do_dbhost(
            args.dry_run,
            args.replace_all,
            dbhost,
            dbport,
            config,
            dbs,
            customviews
        )

    logging.info("All done.")
