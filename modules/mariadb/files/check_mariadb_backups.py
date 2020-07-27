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
            'es4', 'es5', 's10',
            'm1', 'm2', 'm3', 'm4', 'm5', 'tendril', 'zarcillo',
            'matomo', 'analytics_meta']
DATACENTERS = ['eqiad', 'codfw']
TYPES = ['dump', 'snapshot']
DEFAULT_FRESHNESS = 691200  # 8 days, in seconds
DEFAULT_MIN_SIZE = 300 * 1024  # size smaller than 300K is considered failed
DEFAULT_WARN_SIZE_PERCENTAGE = 5  # size of previous ones minus or plus this percentage is weird
DEFAULT_CRIT_SIZE_PERCENTAGE = 15  # size of previous ones minus or plus this percentage is a fail
DEFAULT_SSL_CA = '/etc/ssl/certs/Puppet_Internal_CA.pem'  # CA path used for mysql TLS connection


def get_options():
    parser = argparse.ArgumentParser(description='Checks if backups for a '
                                                 'specific section are fresh.')
    parser.add_argument('--host', '-o', required=True,
                        help='Host with the database to connect to')
    parser.add_argument('--user', '-u', required=True,
                        help='user used for the mysql connection')
    parser.add_argument('--password', '-w', default='',
                        help='Password used for the mysql connection')
    parser.add_argument('--database', '-D', required=True,
                        help='Database where the backup metadata is stored')
    parser.add_argument('--section', '-s', required=True,
                        choices=SECTIONS,
                        help='Database section/shard to check')
    parser.add_argument('--datacenter', '-d', required=True,
                        choices=DATACENTERS,
                        help='Datacenter storage location of the backup to check.')
    parser.add_argument('--type', '-t', required=False,
                        choices=TYPES, default=TYPES[0],
                        help='Type or method of backup, dump or snapshot')
    parser.add_argument('--freshness', '-f', default=DEFAULT_FRESHNESS,
                        type=int,
                        help='Time, in seconds, of how old a backup can be '
                             'before being considered outdated (default: 8 days)')
    parser.add_argument('--min-size', '-c', default=DEFAULT_MIN_SIZE,
                        type=int,
                        help='Size, in bytes, below which the backup is considered '
                             'failed in any case (default: 300 KB)')
    parser.add_argument('--warn-size-percentage', '-p', default=DEFAULT_WARN_SIZE_PERCENTAGE,
                        type=float,
                        help='Percentage of size change compared to previous backups, '
                             'above which a WARNING is produced (default: 5%%)')
    parser.add_argument('--crit-size-percentage', '-P', default=DEFAULT_CRIT_SIZE_PERCENTAGE,
                        type=float,
                        help='Percentage of size change compared to previous backups, '
                             'above which a CRITICAL is produced (default: 15%%)')

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
    if options.type not in TYPES:
        return (UNKNOWN, 'Bad or unrecognized type: {}'.format(options.type))
    type = options.type
    freshness = int(options.freshness)

    # Connect and query the metadata database
    try:
        db = pymysql.connect(host=options.host, user=options.user, password=options.password,
                             database=options.database, ssl={'ca': DEFAULT_SSL_CA})
    except (pymysql.err.OperationalError, pymysql.err.InternalError):
        return (CRITICAL, 'We could not connect to the backup metadata database')
    with db.cursor(pymysql.cursors.DictCursor) as cursor:
        query = "SELECT id, name, status, source, host, type, section, start_date, " \
                "       end_date, total_size " \
                "FROM backups " \
                "WHERE type = '{}' and " \
                "section = '{}' and " \
                "host like '%.{}.wmnet' and " \
                "status = 'finished' and " \
                "end_date IS NOT NULL " \
                "ORDER BY start_date DESC " \
                "LIMIT 2".format(type, section, datacenter)
        try:
            cursor.execute(query)
        except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
            return (CRITICAL, 'Error while querying the backup metadata database')
        data = cursor.fetchall()
        if len(data) < 1:
            return (CRITICAL, 'We could not find any completed {} for '
                              '{} at {}'.format(type, section, datacenter))

        last_backup_date = data[0]['start_date']
        required_backup_date = (datetime.datetime.now()
                                - datetime.timedelta(seconds=freshness))
        present = arrow.utcnow()
        humanized_freshness = present.humanize(present.shift(seconds=freshness))
        size = data[0]['total_size']
        if size is None:
            size = 0
        else:
            size = int(size)
        humanized_size = str(round(size / 1024 / 1024 / 1024)) + ' GB'
        source = data[0]['source']
        min_size = options.min_size
        humanized_min_size = str(round(min_size / 1024)) + ' KB'
        crit_size_percentage = options.crit_size_percentage
        warn_size_percentage = options.warn_size_percentage

        # check backup is fresh enough
        if last_backup_date < required_backup_date:
            return (CRITICAL, '{} for {} at {} taken more than {}: '
                              'Most recent backup {}'.format(type,
                                                             section,
                                                             datacenter,
                                                             humanized_freshness,
                                                             last_backup_date))
        # Check minimum size
        if size < min_size:
            return(CRITICAL, '{} for {} at {} ({}) is less than {}: '
                             '{} bytes'.format(type,
                                               section,
                                               datacenter,
                                               last_backup_date,
                                               humanized_min_size,
                                               size))

        # warn in any case if there is only 1 backup (cannot compare sizes)
        if len(data) == 1:
            return(WARNING, 'There is only 1 {} for {} at {} ({}) '
                            'taken on {} ({})'.format(type,
                                                      section,
                                                      datacenter,
                                                      source,
                                                      last_backup_date,
                                                      humanized_size))

        previous_size = data[1]['total_size']
        humanized_previous_size = str(round(previous_size / 1024 / 1024 / 1024)) + ' GB'
        percentage_change = abs((size - previous_size) / previous_size * 100.0)
        # check size change
        if percentage_change > crit_size_percentage:
            return(CRITICAL, 'Last {} for {} at {} ({}) '
                             'taken on {} is {}, but '
                             'previous one was {}, '
                             'a change of {:.1f}%'.format(type,
                                                          section,
                                                          datacenter,
                                                          source,
                                                          last_backup_date,
                                                          humanized_size,
                                                          humanized_previous_size,
                                                          percentage_change))
        if percentage_change > warn_size_percentage:
            return(WARNING, 'Last {} for {} at {} ({}) '
                            'taken on {} is {}, but '
                            'previous one was {}, '
                            'a change of {:.1f}%'.format(type,
                                                         section,
                                                         datacenter,
                                                         source,
                                                         last_backup_date,
                                                         humanized_size,
                                                         humanized_previous_size,
                                                         percentage_change))
        # TODO: check files expected
        return (OK, 'Last {} for {} at {} ({}) '
                    'taken on {} ({})'.format(type,
                                              section,
                                              datacenter,
                                              source,
                                              last_backup_date,
                                              humanized_size))


def main():

    options = get_options()
    result = check_backup_database(options)
    print(result[1])
    sys.exit(result[0])


if __name__ == "__main__":
    main()
