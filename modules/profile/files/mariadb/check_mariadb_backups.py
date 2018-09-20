#!/usr/bin/python3

import argparse
import datetime
import pymysql
import sys

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

SECTIONS = ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8',
            'x1', 'pc1', 'pc2', 'pc3', 'es1', 'es2', 'es3',
            'm1', 'm2', 'm3', 'm4', 'm5']
DATACENTERS = ['eqiad', 'codfw']

DEFAULT_FRESHNESS = 691200  # 8 days, in seconds

DB_HOST = 'localhost'
DB_USER = 'nagios'
DB_SOCKET = '/run/mysqld/mysqld.sock'
DB_SCHEMA = 'zarcillo'
DB_PASSWORD = ''  # socket authentication


def get_options():
    parser = argparse.ArgumentParser(description='Checks if backups for a '
                                                 'specific section are fresh.')
    parser.add_argument('--section', '-s', required=True,
                        choices=SECTIONS,
                        help='Database section to check')
    parser.add_argument('--datacenter', '-d', required=True,
                        choices=DATACENTERS,
                        help='Datacenter storage location of the backup to check.')
    parser.add_argument('--freshness', '-f', default=DEFAULT_FRESHNESS,
                        type=int,
                        help='Time, in seconds, of how old a backup can be '
                             'before being considered outdated (default: 8 days)')

    return parser.parse_args()


def check_backup_database(options):
    '''
    Connects to the database with the backup metadata and checks for anomalies.
    :param options: structure with a section, datacenter and freshness
    :return: (icinga status code (int), icinga status message)
    '''
    # Check and handle input parameters
    if options.section not in SECTIONS:
        return (UNKNOWN, 'Bad or unrecognized section: {}'.format(options.section))
    section = options.section
    if options.datacenter not in DATACENTERS:
        return (UNKNOWN, 'Bad or unrecognized datacenter: {}'.format(options.datacenter))
    datacenter = options.datacenter
    freshness = int(options.freshness)

    # Connect and query the metadata database
    try:
        db = pymysql.connect(host=DB_HOST, database=DB_SCHEMA,
                             unix_socket=DB_SOCKET,
                             user=DB_USER, password=DB_PASSWORD)
    except (pymysql.err.OperationalError, pymysql.err.InternalError):
        return (CRITICAL, 'We could not connect to the backup metadata database')
    with db.cursor(pymysql.cursors.DictCursor) as cursor:
            query = "SELECT * FROM backups " \
                    "WHERE type = 'dump' and " \
                    "section = '{}' and " \
                    "host like '%.{}.wmnet' and " \
                    "status = 'finished' and " \
                    "end_date IS NOT NULL " \
                    "ORDER BY start_date DESC " \
                    "LIMIT 1".format(section, datacenter)
            try:
                cursor.execute(query)
            except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                return (CRITICAL, 'Error while querying the backup metadata database')
            data = cursor.fetchall()
            if len(data) != 1:
                return (CRITICAL, 'We could not find any completed backup for '
                                  '{} at {}'.format(section, datacenter))

            # check backup is fresh enough
            last_backup_date = data[0]['start_date']
            required_backup_date = (datetime.datetime.now() -
                                    datetime.timedelta(seconds=freshness))
            if last_backup_date < required_backup_date:
                return (CRITICAL, 'Last backup for {} at {} is outdated: '
                                  'Most recent backup {}'.format(section,
                                                                 datacenter,
                                                                 last_backup_date))
            # TODO: check files and sizes
            return (OK, 'Backups for {} at {} are up to date: '
                        'Most recent backup {}'.format(section,
                                                       datacenter,
                                                       last_backup_date))


def main():

    options = get_options()
    result = check_backup_database(options)
    print(result[1])
    sys.exit(result[0])


if __name__ == "__main__":
    main()
