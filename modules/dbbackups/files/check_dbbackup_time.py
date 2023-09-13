#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Checks backups run in the last week and alerts by email
if any took more than a given amount of time in hours.

It will use the following environement variables:

MAX_HOURS - limit number of hours after which it will alert
EMAIL - email recipient
DB_HOST - mysql host of the database backups metadata server
DB_USER - mysql user of the database backups metadata server
DB_PASSWORD - mysql password of the database backups metadata server
DB_SCHEMA - mysql database (schema) of the database backups metadata server

Usage example:
  $ sudo check-es-backups
"""
from datetime import datetime
from email.message import EmailMessage
import os
import smtplib
import socket
import sys

import pymysql


class DatabaseConnectionException(Exception):
    """Internal exception raised when connecting to the metadata database fails
       (e.g. server is down or unreachable, grant issue, etc.)"""


class DatabaseQueryException(Exception):
    """Internal exception raised when querying the metadata database fails (invalid query,
       unexpected data structure, etc.)"""


def query_metadata_database(max_hours, mysql_config_file):
    """
    Connect to and query the metadata database, return the data of all ongoing
    or finished backups that are taking or took more than the given amount of hours
    to run. Return an array of dictionaries with the backup info.
    """
    try:
        database = pymysql.connect(read_default_file=mysql_config_file)
    except (pymysql.err.OperationalError, pymysql.err.InternalError) as ex:
        raise DatabaseConnectionException from ex
    with database.cursor(pymysql.cursors.DictCursor) as cursor:
        query = """   SELECT id, name, status, source, host, type, section, start_date,
                             end_date, total_size
                        FROM backups
                       WHERE start_date >= now() - INTERVAL 1 WEEK
                         AND TIMESTAMPDIFF(SECOND, start_date,
                                 IF(end_date IS NULL, now(), end_date)) > %s
                    ORDER BY id"""
        print(f"About to execute query: {query}", file=sys.stderr)
        max_seconds = max_hours * 3600
        print(f"Max seconds: {max_seconds}", file=sys.stderr)
        try:
            cursor.execute(query, (str(max_seconds), ))
        except (pymysql.err.ProgrammingError, pymysql.err.InternalError) as ex:
            raise DatabaseQueryException from ex
        data = cursor.fetchall()
    return data


def apply_data(data, email_address, max_hours):
    """
    Create a dictionary with the email contents, or return None if there is no long running backup
    """
    if len(data) == 0:
        print("No long running backups found in the last week", file=sys.stderr)
        return None

    hostname = socket.gethostname()
    report_time = datetime.now()
    text = f"Report run at {report_time.isoformat()} at {hostname}.\n\n"
    text += (f"{len(data)} backups were found in the last week "
             f"that took over {max_hours:.1f} hours:\n\n")
    for backup in data:
        datacenter = backup['host'].split('.')[-2]
        if backup['end_date'] is None:  # ongoing backup, normally (or other weird failure)
            duration = report_time - backup['start_date']
            text += (f"* {backup['type']} of {backup['section']} in {datacenter} started at "
                     f"{backup['start_date'].isoformat()} and it is still ongoing ({duration}).\n")
        else:  # finished backup
            duration = backup['end_date'] - backup['start_date']
            text += (f"* {backup['type']} of {backup['section']} in {datacenter} started at "
                     f"{backup['start_date'].isoformat()} and finished at "
                     f"{backup['end_date'].isoformat()} ({duration}).\n")

    text += ("\n\nCheck `https://wikitech.wikimedia.org/wiki/MariaDB/Backups/Long_running`"
             " for more details about this alert.\n")
    print(text, file=sys.stderr)
    msg = EmailMessage()
    msg.set_content(text)
    msg['Subject'] = "[" + hostname + "]: " + sys.argv[0] + \
        " detected long running backups"
    msg['From'] = hostname + '@wikimedia.org'
    msg['To'] = email_address
    return msg


def connection_error_msg(email_address):
    """
    Create an email message when there is a connection error.
    """
    hostname = socket.gethostname()
    report_time = datetime.now()
    text = f"Report run at {report_time.isoformat()} at {hostname}.\n\n"
    text += (f"`{sys.argv[0]}` attempted to run and produced an error "
             f"due to a database connection problem.\n")
    text += ("\n\nCheck `https://wikitech.wikimedia.org/wiki/MariaDB/Backups/Long_running` "
             "for more details about this alert.\n")
    msg = EmailMessage()
    msg.set_content(text)
    msg['Subject'] = "[" + hostname + "]: " + sys.argv[0] + \
        " had an error: Could not connect to the metadata database"
    msg['From'] = hostname + '@wikimedia.org'
    msg['To'] = email_address
    return msg


def query_error_msg(email_address):
    """
    Create an email message when there is a query error.
    """
    hostname = socket.gethostname()
    report_time = datetime.now()
    text = f"Report run at {report_time.isoformat()} at {hostname}.\n\n"
    text += (f"`{sys.argv[0]}` attempted to run and produced an error "
             f"due to a database query problem.\n")
    text += ("\n\nCheck `https://wikitech.wikimedia.org/wiki/MariaDB/Backups/Long_running` "
             "for more details about this alert.\n")
    msg = EmailMessage()
    msg.set_content(text)
    msg['Subject'] = "[" + hostname + "]: " + sys.argv[0] + \
        " had an error: Error querying the database"
    msg['From'] = hostname + '@wikimedia.org'
    msg['To'] = email_address
    return msg


def send_email(message):
    """
    Send an alerting email with the body, heads and recipient defined on the
    message dictionary.
    """
    smtp = smtplib.SMTP('localhost')
    smtp.send_message(message)
    smtp.quit()
    print("Email sent to " + message['To'], file=sys.stderr)


def main():
    """Parse options, query db and print results in icinga format"""
    max_hours = float(os.environ.get('MAX_HOURS', 12.0))
    email_address = os.environ.get('EMAIL', 'root@localhost').strip()
    mysql_config_file = os.environ.get('MYSQL_CONFIG_FILE', '/etc/wmfbackups/my.cnf')

    try:
        data = query_metadata_database(max_hours, mysql_config_file)
    except DatabaseConnectionException:
        try:
            send_email(connection_error_msg(email_address))
        except ConnectionRefusedError:
            print("[ERROR] Database connection failed and email could not be sent", file=sys.stderr)
            sys.exit(4)
        print("[ERROR] Database connection failed. Email sent with details.", file=sys.stderr)
        sys.exit(1)
    except DatabaseQueryException:
        try:
            send_email(query_error_msg(email_address))
        except ConnectionRefusedError:
            print("[ERROR] Database query failed and email could not be sent", file=sys.stderr)
            sys.exit(5)
        print("[ERROR] Database query failed. Email sent with details.", file=sys.stderr)
        sys.exit(2)
    message = apply_data(data, email_address, max_hours)
    if message is not None:
        try:
            send_email(message)
        except ConnectionRefusedError:
            print("[ERROR] Email failed to be sent.", file=sys.stderr)
            sys.exit(3)

    sys.exit(0)


if __name__ == "__main__":
    main()
