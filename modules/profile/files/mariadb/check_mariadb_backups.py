#!/usr/bin/python3

import argparse
import datetime
import sys

import arrow
import pymysql

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3

SECTIONS = ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8',
            'x1', 'pc1', 'pc2', 'pc3', 'es1', 'es2', 'es3',
            'm1', 'm2', 'm3', 'm4', 'm5']
DATACENTERS = ['eqiad', 'codfw']

DEFAULT_FRESHNESS = 691200  # 8 days, in seconds
# TODO: Parametrize?
CRIT_SIZE = 10 * 1024  # backups smaller than 10K are considered failed
WARN_SIZE = 10 * 1024 * 1024 * 1024  # backups smaller than 10 GB are strange

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
            query = "SELECT id, name, status, source, host, type, section, start_date, " \
                    "       end_date, total_size " \
                    "FROM backups " \
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

            last_backup_date = data[0]['start_date']
            required_backup_date = (datetime.datetime.now() -
                                    datetime.timedelta(seconds=freshness))
            present = arrow.utcnow()
            humanized_freshness = present.humanize(present.shift(seconds=freshness))
            size = data[0]['total_size']
            if size is None:
                size = 0
            else:
                size = int(size)
            humanized_size = str(round(size / 1024 / 1024 / 1024)) + ' GB'
            humanized_warn_size = str(round(WARN_SIZE / 1024 / 1024 / 1024)) + ' GB'
            humanized_crit_size = str(round(CRIT_SIZE / 1024)) + ' KB'
            source = data[0]['source']

            # check backup is fresh enough
            if last_backup_date < required_backup_date:
                return (CRITICAL, 'Backup for {} at {} taken more than {}: '
                                  'Most recent backup {}'.format(section,
                                                                 datacenter,
                                                                 humanized_freshness,
                                                                 last_backup_date))
            # check size
            if size < CRIT_SIZE:
                return(CRITICAL, 'Backup for {} at {} ({}) is less than {}: '
                                 '{} bytes'.format(section,
                                                   datacenter,
                                                   humanized_crit_size,
                                                   last_backup_date,
                                                   size))
            if size < WARN_SIZE:
                return (WARNING, 'Backup for {} at {} ({}) is less than {}: '
                                 '{} bytes.'.format(section,
                                                    datacenter,
                                                    humanized_warn_size,
                                                    last_backup_date,
                                                    size))
            # TODO: check files expected
            return (OK, 'Backup for {} at {} taken less than {} and larger than {}: '
                        'Last one {} from {} ({})'.format(section,
                                                          datacenter,
                                                          humanized_freshness,
                                                          humanized_warn_size,
                                                          last_backup_date,
                                                          source,
                                                          humanized_size))


def main():

    options = get_options()
    result = check_backup_database(options)
    print(result[1])
    sys.exit(result[0])


if __name__ == "__main__":
    main()
