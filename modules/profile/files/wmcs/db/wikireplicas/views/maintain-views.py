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
from typing import Dict, List

import yaml
import pymysql


class SchemaOperations:
    def __init__(self, dry_run, replace_all, db, db_size, cursor):
        self.dry_run = dry_run
        self.replace_all = replace_all
        self.db = db
        self.db_p = db + "_p"
        self.db_size = db_size
        self.cursor = cursor
        self.definer = "viewmaster"
        self.views_missing_tables = []

    def write_execute(self, query):
        """Do operation or simulate
        :param query: str
        """
        logging.debug("SQL: %s", query)
        if not self.dry_run:
            self.cursor.execute(query)

    def drop_view(self, view):
        """Drop an obsolete view
        :param view: str
        :return: bool
        """
        self.write_execute(f"drop view {self.db_p}.{view}")
        return not self.table_exists(view, self.db_p)

    def tables(self, database):
        """Get list of tables in a database (views are included)
        :param database: str
        :returns: list
        """
        self.cursor.execute(
            """
            SELECT `table_name`
            FROM `information_schema`.`tables`
            WHERE `table_schema`=%s;
        """,
            args=(database),
        )

        dbtables = self.cursor.fetchall()
        return [t[0] for t in dbtables]

    def user_exists(self, name):
        """Check if a user exists
        :param name: str
        """
        self.cursor.execute(
            """
            SELECT 1
            FROM `mysql`.`user`
            WHERE `user`=%s;
        """,
            args=(name),
        )
        return bool(self.cursor.rowcount)

    def table_exists(self, table, database):
        """Determine whether a table of the given name exists in the database of
        the given name.
        :param table: str
        :param database: str
        :returns: bool
        """

        return table in self.tables(database=database)

    def database_exists(self, database):
        """Verify if a DB exists
        :param database: str
        :return: bool
        """
        self.cursor.execute(
            """
            SELECT `schema_name`
            FROM `information_schema`.`schemata`
            WHERE `schema_name`=%s
        """,
            args=(database,),
        )
        return bool(self.cursor.rowcount)

    def do_fullview(self, view):
        """Check whether the source table exists, and if so, create the view.
        :param view: str
        """
        if self.table_exists(view, self.db):
            # If it does, create or replace the view for it.
            logging.info("[%s.%s] ", self.db_p, view)
            if not self.table_exists(view, self.db_p) or self._confirm(
                "View already exists. Replace?"
            ):
                # Can't use pymysql to build this
                self.write_execute(
                    f"""
                    CREATE OR REPLACE
                    DEFINER={self.definer}
                    VIEW `{self.db_p}`.`{view}`
                    AS SELECT * FROM `{self.db}`.`{view}`;
                """
                )
        else:
            # Some views only exist in CentralAuth, some only in MediaWiki,
            # etc.
            logging.debug(
                (
                    "Skipping full view %s on database %s as the table does not"
                    " seem to exist."
                ),
                view,
                self.db,
            )
            self.views_missing_tables.append(view)

    def check_customview_source(self, view_name, source):
        """Check whether a custom view's particular source exists
        :param view_name: str
        :param source: str
        :return: tuple
        """
        match = re.match(r"^(?:(.*)\.)?([^.]+)$", source)
        if not match:
            raise Exception(
                f"Custom view source does not look valid! "
                f"Source: {source}, view: {view_name}"
            )

        # Effectively separate a db.table source into it's parts
        source_db, source_table = match.groups()

        # If there was no DB part, assume the current DB name
        if source_db is None:
            source_db = self.db

        if self.table_exists(source_table, source_db):
            # If it does, take this source into account.
            return source_db, source_table

        logging.debug(
            (
                "Failed to find table %s in database %s as a source for"
                " view %s"
            ),
            source_table,
            source_db,
            view_name,
        )
        return ()

    def do_customview(self, view_name, view_details):
        """Process a custom view's sources, and if they're all present, and the
        view's limit is not bigger than the database size, call create_customview.
        :param view_name: str
        :param view_details: str
        """
        if (
            "limit" in view_details
            and self.db_size is not None
            and view_details["limit"] > self.db_size
        ):
            # Ignore custom views which have a limit number greater
            # than the size ID set by the read_list calls for
            # size.dblist above.
            logging.info(
                "Skipping %s: DB size %d < required %d.",
                view_name,
                self.db_size,
                view_details["limit"],
            )
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
            sources_checked.append(f"`{source_db}`.`{source_table}`")

        # This cannot process a left-joined view that has multiple source tables
        # in the sources array
        if len(sources) > 1 and "join" in view_details:
            logging.warning(
                "I don't know how to do joins with multiple sources: %s",
                view_name,
            )
            return

        # Check that joined table exists if used
        if "join" in view_details:
            joins_checked = []
            joined_table_list = []
            for join_def in view_details["join"]:
                joined_table_list.extend(extract_tables(join_def))

            joined_tables = set(joined_table_list)
            for joined_table in joined_tables:
                result = self.check_customview_source(view_name, joined_table)
                if not result:
                    break
                source_db, j_table = result
                joins_checked.append(f"`{source_db}`.`{j_table}`")

            if len(joined_tables) != len(joins_checked):
                # If any joined source was not found, ignore this view.
                # Some views only exist in CentralAuth, some only in MediaWiki,
                # etc.
                logging.debug(
                    (
                        "Skipping custom view %s on database %s as not all joined sources"
                        " were verified.\nJoins requested: %s\nVerified sources: %s"
                    ),
                    view_name,
                    self.db,
                    str(view_details["join"]),
                    str(joins_checked),
                )
                self.views_missing_tables.append(view_name)
                return

        if len(sources) == len(sources_checked):
            if not self.table_exists(view_name, self.db_p) or self._confirm(
                "View already exists. Replace?"
            ):
                logging.info("[%s.%s] ", self.db_p, view_name)
                self.create_customview(view_name, view_details, sources_checked)
        else:
            # If any source was not found, ignore this view.
            # Some views only exist in CentralAuth, some only in MediaWiki,
            # etc.
            logging.debug(
                (
                    "Skipping custom view %s on database %s as not all sources"
                    " were verified.\nSources: %s\nVerified sources: %s"
                ),
                view_name,
                self.db,
                str(view_details["source"]),
                str(sources_checked),
            )
            self.views_missing_tables.append(view_name)

    def create_customview(self, view_name, view_details, sources):
        """Creates or replaces a custom view from its sources.
        :param view_name: str
        :param view_details: dict
        :param sources: list
        """

        query = f"""
            CREATE OR REPLACE
            DEFINER={self.definer}
            VIEW `{self.db_p}`.`{view_name}`
            AS {view_details["view"]}
            FROM {",".join(sources)}
        """

        # Note that we are only doing left outer joins for now.
        # To do an inner join, use multiple sources and a where clause.
        # Combining the two won't work right now.
        if "join" in view_details:
            for join in view_details["join"]:
                if isinstance(join["table"], list):
                    join_table = "("
                    for subjoin in join["table"]:
                        s_table = f"`{self.db}`.`{subjoin['table']}`"
                        if "type" not in subjoin:
                            join_table += f"{s_table}"
                        else:
                            join_table += f" {subjoin['type']} {s_table} {subjoin['condition']}"
                    join_table += ")"

                else:
                    join_table = f"`{self.db}`.`{join['table']}`"

                query += f" LEFT JOIN {join_table} {join['condition']}"

        if "where" in view_details:
            # The comment table (and perhaps others in the future) needs the
            # database name interpolated in after FROM clauses in the WHERE.
            # This will only allow single sources for each SELECT in such complex
            # WHEREs, and if you have multiple source SELECTs in one, it is perhaps
            # time to re-evaluate our strategy overall.
            if re.match(
                r"^.*\bselect\b.+\bfrom",
                view_details["where"],
                flags=re.I | re.M,
            ):
                where_str = re.sub(
                    r"from\s+(\w+)\b",
                    r"from `{}`.`\1` ".format(self.db),
                    view_details["where"],
                    flags=re.I | re.M,
                )
                where_str = re.sub(
                    r"join\s+(\w+)\b",
                    r"join `{}`.`\1` ".format(self.db),
                    where_str,
                    flags=re.I | re.M,
                )

                query += f" WHERE {where_str}\n"
            else:
                query += f" WHERE {view_details['where']}\n"

        if "logging_where" in view_details:
            if "$INSERTED_EXPR$" in query:
                query = query.replace(
                    "$INSERTED_EXPR$",
                    (
                        " log_type IN ('"
                        + "', '".join(view_details["logging_where"])
                        + "')\n"
                    ),
                )
            else:
                query += (
                    "log_type IN ('"
                    + "', '".join(view_details["logging_where"])
                    + "')\n"
                )

        if "group" in view_details:
            # Technically nothing is using this at the moment...
            query += f" GROUP BY {view_details['group']}\n"

        query += ";"

        # Can't use pymysql to build this
        self.write_execute(query)

    def execute(self, fullviews, customviews):
        """Begin checking/creating views for this schema.
        :param fullviews: list
        :param customviews: dict
        """
        self.views_missing_tables = []

        if not self.database_exists(self.db):
            logging.warning("DB %s does not exist to create views", self.db)
            return

        if not self.database_exists(self.db_p):
            # Can't use pymysql to build this
            self.write_execute(
                "GRANT SELECT, SHOW VIEW ON `{}`.* TO 'labsdbuser';".format(
                    self.db_p.replace("_", "\\_")
                )
            )
            self.write_execute(f"CREATE DATABASE `{self.db_p}`;")

        logging.info("Full views for %s:", self.db)
        for view in fullviews:
            self.do_fullview(view)

        logging.info("Custom views for %s:", self.db)
        for view_name, view_details in customviews.items():
            self.do_customview(view_name, view_details)

    def drop_public_database(self):
        """Drop a public database entirely."""
        if self.database_exists(self.db_p):
            if self._confirm(f"Drop {self.db_p}?"):
                self.write_execute(f"DROP DATABASE `{self.db_p}`;")
        else:
            logging.warning("DB %s does not exist", self.db_p)

    def _confirm(self, msg):
        """Prompt for confirmation unless self.replace_all is true."""
        return self.replace_all or input(f"{msg} [y/N] ").lower() in [
            "y",
            "yes",
        ]


def extract_tables(join_def):
    """Get the list of tables we are interacting with in a join field
    :param join_dev: dict
    :return: list
    """
    if isinstance(join_def["table"], str):
        return [join_def["table"]]

    return [x["table"] for x in join_def["table"]]


def read_dblist(db_list, mwroot):
    """Read a dblist from disk."""
    dbs_file = f"{mwroot}/dblists/{db_list}.dblist"
    with open(dbs_file) as f:
        lines = f.read().splitlines()
    if not lines:
        raise RuntimeError(f"No databases found in dblist {db_list}")
    dbs = []
    for line in lines:
        # Strip comments and trim whitespace
        comment = line.find("#")
        if comment == 0:
            # Ignore lines that are only comments
            continue
        if comment != -1:
            # Remove inline comments
            line = line[:comment]
        line = line.strip()
        if line.startswith("%%"):
            if dbs:
                raise RuntimeError(
                    f"Encountered a dblist expression inside dblist {db_list}"
                )
            dbs = eval_dblist(line, mwroot)
            break
        elif line:
            dbs.append(line)
    return dbs


def eval_dblist(expr, mwroot):
    """Evaluate a dblist expression."""
    expr = expr.trim("% ")
    terms = expr.split()
    # assume the expr is well formed and that the first element is always
    # a list name
    dbs = set(read_dblist(terms.pop(0), mwroot))
    # assume the rest of the terms are well formed and (op, list) pairs
    for op, term in zip(*[iter(terms)] * 2):
        part = set(read_dblist(term, mwroot))
        if op == "+":
            dbs = dbs.union(part)
        elif op == "-":
            dbs = dbs.difference(part)
    return sorted(list(dbs))


def dbrun(
    db_connections: Dict[str, pymysql.connections.Connection],
    instance: str,
    dbs_with_metadata: Dict[str, Dict],
    dry_run: bool,
    replace_all: bool,
    drop: bool,
    fullviews: List[str],
    clean: bool,
    customviews: Dict[str, Dict],
    all_tables: List[str],
) -> int:
    exit_status = 0
    with db_connections[instance].cursor() as cursor:
        cursor.execute("SET NAMES 'utf8';")
        cursor.execute("SET SESSION innodb_lock_wait_timeout=1;")
        cursor.execute("SET SESSION lock_wait_timeout=60;")

        for db, db_info in dbs_with_metadata.items():
            ops = SchemaOperations(
                dry_run,
                replace_all,
                db,
                db_info.get("size", None),
                cursor,
            )

            if not ops.user_exists(ops.definer):
                logging.critical("Definer has not been created")
                return 1

            if drop:
                ops.drop_public_database()
                continue

            ops.execute(fullviews, customviews)

            if clean:
                logging.info("cleanup is enabled")
                live_tables = ops.tables(ops.db_p)
                clean_tables = set(
                    [t for t in live_tables if t not in all_tables]
                    + [t for t in ops.views_missing_tables if t in live_tables]
                )
                logging.info("cleaning %s tables", len(clean_tables))
                for dt in clean_tables:
                    logging.info("Dropping view %s.%s", ops.db_p, dt)
                    try:
                        ops.drop_view(dt)
                    except pymysql.err.MySQLError:
                        exit_status = 1
                        logging.exception(
                            "Error dropping view %s.%s", ops.db_p, dt
                        )
    return exit_status


def main():
    exit_status = 0
    argparser = argparse.ArgumentParser(
        "maintain-views",
        description="Maintain labsdb sanitized views of replica databases",
    )

    group = argparser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--databases",
        help=(
            "Specify database(s) to work on, instead of all. Multiple"
            " values can be given space-separated."
        ),
        nargs="+",
    )
    group.add_argument(
        "--all-databases",
        help="Flag to run through all possible databases",
        action="store_true",
    )
    argparser.add_argument(
        "--config-location",
        help="Path to find the configuration file",
        default="/etc/maintain-views.yaml",
    )
    argparser.add_argument(
        "--table", help="Specify a single table to act on", default=""
    )
    argparser.add_argument(
        "--dry-run",
        help=(
            "Give this parameter if you don't want the script to actually"
            " make changes."
        ),
        action="store_true",
    )
    argparser.add_argument(
        "--clean",
        help="Clean out views from _p db that are no longer specified.",
        action="store_true",
    )
    argparser.add_argument(
        "--drop", help="Remove _p db entirely.", action="store_true"
    )
    argparser.add_argument(
        "--replace-all",
        help=(
            "Give this parameter if you don't want the script to prompt"
            " before replacing views."
        ),
        action="store_true",
    )
    argparser.add_argument(
        "--mediawiki-config",
        help=(
            "Specify path to mediawiki-config checkout"
            " values can be given space-separated."
        ),
        default="/usr/local/lib/mediawiki-config",
    )

    argparser.add_argument(
        "--debug", help="Turn on debug logging", action="store_true"
    )

    args = argparser.parse_args()

    # argparse mutually exclusive is weird http://bugs.python.org/issue10984
    if args.table and args.clean:
        logging.critical("cannot specify a single table and cleanup")
        return 2

    if args.drop and not args.databases:
        logging.critical("--drop must specify database names")
        return 2

    with open(args.config_location, "r") as stream:
        try:
            config = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            logging.critical(exc)
            return 2

    all_tables = []
    all_tables = all_tables + config["fullviews"]
    all_tables = all_tables + config["allowed_logtypes"]
    all_tables = all_tables + list(config["customviews"].keys())

    if args.table:
        fullviews = [t for t in config["fullviews"] if t == args.table]

        customviews = {}
        for view, meta in config["customviews"].items():
            if meta["source"] == args.table:
                customviews[view] = config["customviews"][view]
    else:
        fullviews = config["fullviews"]
        customviews = config["customviews"]

    dbs_metadata = config["metadata"]
    sensitive_db_lists = config["sensitive_db_lists"]

    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.INFO,
    )

    db_connections = {}
    try:
        for instance in config["mysql_instances"]:
            socket = f"/run/mysqld/mysqld.{instance}.sock"
            db_connections[instance] = pymysql.connect(
                user=config["mysql_user"],
                passwd=config["mysql_password"],
                unix_socket=socket,
                charset="utf8",
            )

        # This will include private and deleted dbs at this stage
        all_available_dbs = []
        for inst in config["mysql_instances"]:
            all_available_dbs.extend(read_dblist(inst, args.mediawiki_config))
            if inst in config["add_to_all_dbs"].keys():
                all_available_dbs.extend(config["add_to_all_dbs"][inst])

        # argparse will ensure we are declaring explicitly
        dbs = all_available_dbs
        if args.databases:
            dbs = [db for db in args.databases if db in all_available_dbs]

        if not dbs:
            logging.info("This server doesn't host that database")
            return 0

        # purge all sensitive dbs so they are never attempted
        allowed_dbs = dbs
        for db_list in sensitive_db_lists:
            pdbs = read_dblist(db_list, args.mediawiki_config)
            allowed_dbs = [x for x in allowed_dbs if x not in pdbs]

        logging.debug("Removing %s dbs as sensitive", len(dbs) - len(allowed_dbs))
        if not allowed_dbs:
            logging.error("None of the specified dbs are allowed")
            return 1

        # assign all metadata from lists
        dbs_with_metadata = {x: {} for x in allowed_dbs}
        for db_list, meta in dbs_metadata.items():
            for db in read_dblist(db_list, args.mediawiki_config):
                if db in dbs_with_metadata:
                    dbs_with_metadata[db].update(meta)

        # At this point we are on a multi-instance replica
        dbs_in_scope = set(dbs_with_metadata.keys())
        for inst in config["mysql_instances"]:
            dbs_for_section = read_dblist(inst, args.mediawiki_config)
            if inst in config["add_to_all_dbs"].keys():
                dbs_for_section.extend(config["add_to_all_dbs"][inst])

            dbs_in_section = set(dbs_for_section)
            instance_dbs = dbs_in_scope.intersection(dbs_in_section)
            instance_dbs_with_metadata = {
                db: meta
                for (db, meta) in dbs_with_metadata.items()
                if db in instance_dbs
            }
            if instance_dbs_with_metadata:
                exit_status = dbrun(
                    db_connections,
                    inst,
                    instance_dbs_with_metadata,
                    args.dry_run,
                    args.replace_all,
                    args.drop,
                    fullviews,
                    args.clean,
                    customviews,
                    all_tables,
                )
                if exit_status != 0:
                    break

        return exit_status
    finally:
        for _, conn in db_connections.items():
            conn.close()


if __name__ == "__main__":
    sys.exit(main())
