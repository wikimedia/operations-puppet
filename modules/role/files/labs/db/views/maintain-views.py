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
#  This script maintains the databases containing sanitized views to
#  the replicated databases (in the form <db>_p for every <db>)
#
#  Information on available and operational databases is sourced from
#  a checkout of mediawiki-config.
#

import argparse
import logging
import re
import sys
import yaml

import pymysql


class SchemaOperations():
    def __init__(self, dry_run, replace_all, db, db_size, cursor):
        self.dry_run = dry_run
        self.replace_all = replace_all
        self.db = db
        self.db_p = db + '_p'
        self.db_size = db_size
        self.cursor = cursor
        self.definer = 'viewmaster'

    def write_execute(self, query):
        """ Do operation or simulate
        :param query: str
        """
        logging.debug("SQL: {}".format(query))
        if not self.dry_run:
            self.cursor.execute(query)

    def drop_view(self, view):
        """ Drop an obsolete view
        :param view: str
        :return: bool
        """
        self.write_execute("drop view {}.{}".format(self.db_p, view))
        return not self.table_exists(view, self.db_p)

    def tables(self, database):
        """ Get list of tables in a database (views are included)
        :param database: str
        :returns: list
        """
        self.cursor.execute("""
            SELECT `table_name`
            FROM `information_schema`.`tables`
            WHERE `table_schema`=%s;
        """, args=(database))

        dbtables = self.cursor.fetchall()
        return [t[0] for t in dbtables]

    def user_exists(self, name):
        """ Check if a user exists
        :param name: str
        """
        self.cursor.execute("""
            SELECT 1
            FROM `mysql`.`user`
            WHERE `user`=%s;
        """, args=(name))
        return bool(self.cursor.rowcount)

    def table_exists(self, table, database):
        """ Determine whether a table of the given name exists in the database of
        the given name.
        :param table: str
        :param database: str
        :returns: bool
        """
        return table in self.tables(database=database)

    def database_exists(self, database):
        """ Verify if a DB exists
        :param database: str
        :return: bool
        """
        self.cursor.execute("""
            SELECT `schema_name`
            FROM `information_schema`.`schemata`
            WHERE `schema_name`=%s
        """, args=(database,))
        return bool(self.cursor.rowcount)

    def do_fullview(self, view):
        """ Check whether the source table exists, and if so, create the view.
        :param view: str
        """
        if self.table_exists(view, self.db):
            # If it does, create or replace the view for it.
            logging.info("[{}] ".format(view))
            if (
                not self.table_exists(view, self.db_p) or
                self._confirm('View already exists. Replace?)
            ):
                # Can't use pymysql to build this
                self.write_execute("""
                    CREATE OR REPLACE
                    DEFINER={0}
                    VIEW `{1}`.`{2}`
                    AS SELECT * FROM `{3}`.`{2}`;
                """.format(self.definer, self.db_p, view, self.db))
        else:
            # Some views only exist in CentralAuth, some only in MediaWiki,
            # etc.
            logging.debug(
                ("Skipping full view {} on database {} as the table does not"
                    " seem to exist.")
                .format(view, self.db)
            )

    def check_customview_source(self, view_name, source):
        """ Check whether a custom view's particular source exists
        :param view_name: str
        :param source: str
        :return: tuple
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
            return ()

    def do_customview(self, view_name, view_details):
        """ Process a custom view's sources, and if they're all present, and the
        view's limit is not bigger than the database size, call create_customview.
        :param view_name: str
        :param view_details: str
        """
        if ("limit" in view_details and self.db_size is not None and
                view_details["limit"] > self.db_size):
            # Ignore custom views which have a limit number greater
            # than the size ID set by the read_list calls for
            # size.dblist above.
            logging.warning("Too big for this database")
            return

        sources = view_details["source"]
        if sources.__class__ is str:
            sources = [sources]

        sources_checked = []

        for source in sources:
            result = self.check_customview_source(view_name, source)
            if not result:
                break
            source_db, source_table = result
            sources_checked.append(
                "`{}`.`{}`".format(source_db, source_table)
            )

        if len(sources) == len(sources_checked):

            if (
                not self.table_exists(view_name, self.db_p) or
                self._confirm('View already exists. Replace?')
            ):
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
        """ Creates or replaces a custom view from its sources.
        :param view_name: str
        :param view_details: dict
        :param sources: list
        """

        query = """
            CREATE OR REPLACE
            DEFINER={}
            VIEW `{}`.`{}`
            AS {}
            FROM {}
        """.format(
            self.definer,
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

    def execute(self, fullviews, customviews):
        """ Begin checking/creating views for this schema.
        :param fullviews: list
        :param customviews: dict
        """

        if not self.database_exists(self.db):
            logging.warning('DB {} does not exist to create views'.format(self.db))
            return

        if not self.database_exists(self.db_p):
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

    def drop_public_database(self):
        """Drop a public database entirely."""
        if self.database_exists(self.db_p):
            if self._confirm('Drop {}?'.format(self.db_p):
                self.write_execute("DROP DATABASE `{}`;".format(self.db_p))
        else:
            logging.warning('DB {} does not exist'.format(self.db_p))

    def _confirm(self, msg):
        return (
            self.replace_all or
            input("{} [y/N] ".format(msg)).lower() in ['y', 'yes']
        )


if __name__ == "__main__":

    argparser = argparse.ArgumentParser(
        "maintain-views",
        description="Maintain labsdb sanitized views of replica databases"
    )

    group = argparser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--databases',
        help=("Specify database(s) to work on, instead of all. Multiple"
              " values can be given space-separated."),
        nargs="+"
    )
    group.add_argument(
        '--all-databases',
        help='Flag to run through all possible databases',
        action='store_true',
    )
    argparser.add_argument(
        "--config-location",
        help="Path to find the configuration file",
        default="/etc/maintain-views.yaml"
    )
    argparser.add_argument(
        "--table",
        help="Specify a single table to act on (currently only fullviews are supported)",
        default=''
    )
    argparser.add_argument(
        "--dry-run",
        help=("Give this parameter if you don't want the script to actually"
              " make changes."),
        action="store_true"
    )
    argparser.add_argument(
        "--clean",
        help="Clean out views from _p db that are no longer specified.",
        action="store_true"
    )
    argparser.add_argument(
        "--drop",
        help="Remove _p db entirely.",
        action="store_true"
    )
    argparser.add_argument(
        "--replace-all",
        help=("Give this parameter if you don't want the script to prompt"
              " before replacing views."),
        action="store_true"
    )
    argparser.add_argument(
        "--mediawiki-config",
        help=("Specify path to mediawiki-config checkout"
              " values can be given space-separated."),
        default="/usr/local/lib/mediawiki-config"
    )

    argparser.add_argument(
        "--mysql-socket",
        help=("Path to MySQL socket file"),
        default="/run/mysqld/mysqld.sock"
    )

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )

    args = argparser.parse_args()

    # argparse mutually exclusive is weird http://bugs.python.org/issue10984
    if args.table and args.clean:
        logging.critical("cannot specify a single table and cleanup")
        sys.exit(1)

    if args.drop and not args.databases:
        logging.critical("--drop must specify database names")
        sys.exit(1)

    with open(args.config_location, 'r') as stream:
        try:
            config = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            logging.critical(exc)
            sys.exit(1)

    all_tables = []
    all_tables = all_tables + config['fullviews']
    all_tables = all_tables + config['logging_whitelist']
    all_tables = all_tables + list(config['customviews'].keys())

    if args.table:
        fullviews = [t for t in config["fullviews"] if t == args.table]

        customviews = {}
        for view, meta in config['customviews'].items():
            if meta['source'] == args.table:
                customviews[view] = config['customviews'][view]
    else:
        fullviews = config['fullviews']
        customviews = config['customviews']

    dbs_metadata = config['metadata']
    sensitive_db_lists = config['sensitive_db_lists']

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO,
    )

    dbh = pymysql.connect(
        user=config["mysql_user"],
        passwd=config["mysql_password"],
        unix_socket=args.mysql_socket,
        charset="utf8"
    )

    # This is weirdly arranged and should be cleaned up
    # to be more explicit at the config file layer
    if 'logging' in customviews.keys():
        safelog = ("log_type IN ('" +
                   "', '".join(config["logging_whitelist"]) +
                   "')")
        customviews["logging"]["where"] = safelog
        customviews["logging_logindex"]["where"] = ("(log_deleted&1)=0 and " +
                                                    safelog)
        customviews["logging_userindex"]["where"] = ("(log_deleted&4)=0 and " +
                                                     safelog)

    # This will include private and deleted dbs at this stage
    all_dbs_file = "{}/dblists/all.dblist".format(args.mediawiki_config)
    with open(all_dbs_file) as f:
        all_available_dbs = f.read().splitlines()
    all_available_dbs = all_available_dbs + config['add_to_all_dbs']

    # argparse will ensure we are declaring explicitly
    dbs = all_available_dbs
    if args.databases:
        dbs = [db for db in args.databases if db in all_available_dbs]

    # purge all sensitive dbs so they are never attempted
    allowed_dbs = dbs
    for list in sensitive_db_lists:
        path = "{}/dblists/{}.dblist".format(args.mediawiki_config, list)
        with open(path) as file:
            pdbs = [db for db in file.read().splitlines()]
            allowed_dbs = [x for x in allowed_dbs if x not in pdbs]

    logging.debug("Removing {} dbs as sensitive".format(len(dbs) - len(allowed_dbs)))
    if not allowed_dbs:
        logging.error('None of the specified dbs are allowed')
        sys.exit(1)

    # assign all metadata from lists
    dbs_with_metadata = {x: {} for x in allowed_dbs}
    for list, meta in dbs_metadata.items():
        path = "{}/dblists/{}.dblist".format(args.mediawiki_config, list)
        with open(path) as file:
            mdbs = [db for db in file.read().splitlines()]
        for db in mdbs:
            if db in dbs_with_metadata:
                dbs_with_metadata[db].update(meta)

    with dbh.cursor() as cursor:
        cursor.execute("SET NAMES 'utf8';")
        cursor.execute("SET SESSION innodb_lock_wait_timeout=1;")
        cursor.execute("SET SESSION lock_wait_timeout=60;")

        for db, db_info in dbs_with_metadata.items():
            ops = SchemaOperations(args.dry_run,
                                   args.replace_all,
                                   db,
                                   db_info.get('size', None),
                                   cursor)

            if not ops.user_exists(ops.definer):
                logging.critical("Definer has not been created")
                sys.exit(1)

            if args.drop:
                ops.drop_public_database()
                continue

            ops.execute(fullviews, customviews)

            if args.clean:
                logging.info('cleanup is enabled')
                live_tables = ops.tables(ops.db_p)
                dead_tables = [t for t in live_tables if t not in all_tables]
                logging.info('cleaning {} tables'.format(len(dead_tables)))
                for dt in dead_tables:
                    logging.info("Dropping view {}".format(dt))
                    ops.drop_view(dt)
