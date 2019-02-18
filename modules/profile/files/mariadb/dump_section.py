#!/usr/bin/python3

import argparse
import datetime
import logging
import os
import pymysql
import re
import shutil
import socket
import subprocess
import sys
from multiprocessing.pool import ThreadPool
import yaml

DEFAULT_CONFIG_FILE = '/etc/mysql/backups.cnf'
DEFAULT_THREADS = 18
DEFAULT_TYPE = 'dump'
CONCURRENT_BACKUPS = 2
DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 3306
DEFAULT_ROWS = 20000000
DEFAULT_USER = 'root'
RETENTION_DAYS = 18
DEFAULT_BACKUP_DIR = '/srv/tmp'
ONGOING_LOGICAL_BACKUP_DIR = '/srv/backups/dumps/ongoing'
FINAL_LOGICAL_BACKUP_DIR = '/srv/backups/dumps/latest'
ARCHIVE_LOGICAL_BACKUP_DIR = '/srv/backups/dumps/archive'
ONGOING_RAW_BACKUP_DIR = '/srv/backups/snapshots/ongoing'
FINAL_RAW_BACKUP_DIR = '/srv/backups/snapshots/latest'
ARCHIVE_RAW_BACKUP_DIR = '/srv/backups/snapshots/archive'

DATE_FORMAT = '%Y-%m-%d--%H-%M-%S'
# FIXME: backups will stop working on Jan 1st 2100
DUMPNAME_REGEX = 'dump\.([a-z0-9\-]+)\.(20\d\d-[01]\d-[0123]\d\--\d\d-\d\d-\d\d)'
SNAPNAME_REGEX = 'snapshot\.([a-z0-9\-]+)\.(20\d\d-[01]\d-[0123]\d\--\d\d-\d\d-\d\d)'
DUMPNAME_FORMAT = 'dump.{0}.{1}'  # where 0 is the section and 1 the date
SNAPNAME_FORMAT = 'snapshot.{0}.{1}'  # where 0 is the section and 1 the date

TLS_TRUSTED_CA = '/etc/ssl/certs/Puppet_Internal_CA.pem'


class BackupStatistics:
    """
    Virtual class that defines the interface to generate
    and store the backup statistics.
    """
    host = None
    port = 3306
    user = None
    password = None
    dump_name = None
    backup_dir = None

    def __init__(self, dump_name, section, type, source, backup_dir, config):
        self.dump_name = dump_name
        self.section = section
        self.source = source
        self.backup_dir = backup_dir
        self.host = config.get('host', DEFAULT_HOST)
        self.port = config.get('port', DEFAULT_PORT)
        self.database = config['database']
        self.user = config.get('user', DEFAULT_USER)
        self.password = config['password']
        self.type = type

    def start(self):
        pass

    def gather_metrics(self):
        pass

    def fail(self):
        pass

    def finish(self):
        pass

    def delete(self):
        pass


class DisabledBackupStatistics(BackupStatistics):
    """
    Dummy class that does nothing when statistics are requested to be
    generated and stored.
    """
    def __init__(self):
        pass


class DatabaseBackupStatistics(BackupStatistics):
    """
    Generates statistics and stored them on a MySQL/MariaDB database over TLS
    """

    def set_status(self, status):
        """
        Updates or inserts the backup entry at the backup statistics
        database, with the given status (ongoing, finished, failed).
        If it is ongoing, it is considered a new entry (in which case,
        section and source are required parameters.
        Otherwise, it supposes an existing entry with the given name
        exists, and it tries to update it.
        Returns True if it was successful, False otherwise.
        """
        logger = logging.getLogger('backup')
        try:
            db = pymysql.connect(host=self.host, port=self.port, database=self.database,
                                 user=self.user, password=self.password,
                                 ssl={'ca': TLS_TRUSTED_CA})
        except (pymysql.err.OperationalError):
            logger.exception('We could not connect to {} to store the stats'.format(self.host))
            return False
        with db.cursor(pymysql.cursors.DictCursor) as cursor:
            if status == 'ongoing':
                if self.section is None or self.source is None:
                    logger.error('A new backup requires a section and a source parameters')
                    return False
                host = socket.getfqdn()
                query = "INSERT INTO backups (name, status, section, source, host, type," \
                        "start_date, end_date) " \
                        "VALUES (%s, 'ongoing', %s, %s, %s, %s, now(), NULL)"
                try:
                    result = cursor.execute(query, (self.dump_name, self.section, self.source,
                                            host, self.type))
                except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                    logger.error('A MySQL error occurred while trying to insert the entry '
                                 'for the new backup')
                    return False
                if result is None:
                    logger.error('We could not store the information on the database')
                    return False
                db.commit()
            elif status in ('finished', 'failed', 'deleted'):
                query = "SELECT id, status FROM backups WHERE name = %s"
                try:
                    result = cursor.execute(query, (self.dump_name,))
                except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                    logger.error('A MySQL error occurred while finding the entry for the '
                                 'backup')
                    return False
                if result is None:
                    logger.error('We could not update the database backup statistics server')
                    return False
                data = cursor.fetchall()
                if len(data) != 1:
                    logger.error('We could not find the existing statistics for the finished '
                                 'dump')
                    return False
                elif data[0]['status'] == status:
                    logger.warning('We are already on the {} state'.format(status))
                    return True
                else:
                    backup_id = str(data[0]['id'])
                    query = "UPDATE backups SET status = %s, end_date = now() WHERE id = %s"
                    try:
                        result = cursor.execute(query, (status, backup_id))
                    except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                        logger.error('A MySQL error occurred while trying to update the '
                                     'entry for the new backup')
                        return False

                    if result is None:
                        logger.error('We could not set as finished the current dump')
                        return False
                    db.commit()
                    return True
            else:
                logger.error('Invalid status: {}'.format(status))
                return False

    def gather_metrics(self):
        """
        Gathers the file name list, last modification and sizes for the generated files
        and stores it on the given statistics mysql database.
        """
        logger = logging.getLogger('backup')
        # Find the completed backup db entry
        try:
            db = pymysql.connect(host=self.host, port=self.port, database=self.database,
                                 user=self.user, password=self.password,
                                 ssl={'ca': TLS_TRUSTED_CA})
        except (pymysql.err.OperationalError):
            logger.exception('We could not connect to {} to store the stats'.format(self.host))
            return False
        with db.cursor(pymysql.cursors.DictCursor) as cursor:
            query = "SELECT id, status FROM backups WHERE name = %s"
            try:
                result = cursor.execute(query, (self.dump_name,))
            except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                logger.error('A MySQL error occurred while finding the entry for the '
                             'backup')
                return False
            if result is None:
                logger.error('We could not update the database backup statistics server')
                return False
            data = cursor.fetchall()
            if len(data) != 1:
                logger.error('We could not find the existing statistics for the finished '
                             'dump')
                return False
            backup_id = str(data[0]['id'])

        total_size = 0
        # Insert the backup file list
        for file in sorted(os.listdir(self.backup_dir)):
            name = file
            statinfo = os.stat(os.path.join(self.backup_dir, file))
            size = statinfo.st_size
            total_size += size
            time = statinfo.st_mtime
            # TODO: Identify which object this files corresponds to and record it on
            #       backup_objects
            with db.cursor(pymysql.cursors.DictCursor) as cursor:
                query = "INSERT INTO backup_files VALUES (%s, %s, %s, FROM_UNIXTIME(%s), NULL)"
                try:
                    result = cursor.execute(query, (backup_id, name, size, time))
                except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                    logger.error('A MySQL error occurred while inserting the backup '
                                 'file details')
                    return False
        # Update the total backup size
        with db.cursor(pymysql.cursors.DictCursor) as cursor:
            query = "UPDATE backups SET total_size = %s WHERE id = %s"
            try:
                result = cursor.execute(query, (total_size, backup_id))
            except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                logger.error('A MySQL error occurred while updating the total backup size')
                return False
        db.commit()
        return True

    def start(self):
        self.set_status('ongoing')

    def fail(self):
        self.set_status('failed')

    def finish(self):
        self.set_status('finished')

    def delete(self):
        self.set_status('deleted')


def get_mydumper_cmd(name, config):
    """
    Given a config, returns a command line for mydumper, the name
    of the expected dump, and the log path.
    """
    # FIXME: even if there is not privilege escalation (everybody can run
    # mydumper and parameters are gotten from a localhost file),
    # check parameters better to avoid unintended effects
    cmd = ['/usr/bin/mydumper']
    cmd.extend(['--compress', '--events', '--triggers', '--routines'])
    backup_dir = config.get('backup_dir', ONGOING_LOGICAL_BACKUP_DIR)

    log_file = os.path.join(backup_dir, 'dump_log.{}'.format(name))
    cmd.extend(['--logfile', log_file])
    formatted_date = datetime.datetime.now().strftime(DATE_FORMAT)
    dump_name = DUMPNAME_FORMAT.format(name, formatted_date)
    output_dir = os.path.join(backup_dir, dump_name)
    cmd.extend(['--outputdir', output_dir])

    rows = int(config.get('rows', DEFAULT_ROWS))
    cmd.extend(['--rows', str(rows)])
    cmd.extend(['--threads', str(config['threads'])])
    host = config.get('host', DEFAULT_HOST)
    cmd.extend(['--host', host])
    port = int(config.get('port', DEFAULT_PORT))
    cmd.extend(['--port', str(port)])
    if 'regex' in config and config['regex'] is not None:
        cmd.extend(['--regex', config['regex']])

    if 'user' in config:
        cmd.extend(['--user', config['user']])
    if 'password' in config:
        cmd.extend(['--password', config['password']])

    return (cmd, dump_name, log_file)


def get_xtrabackup_cmd(name, config):
    """
    Given a config, returns a command line for mydumper, the name
    of the expected snapshot, and the log path.
    """
    cmd = ['/opt/wmf-mariadb101/bin/mariabackup']
    cmd.extend(['--backup'])
    backup_dir = config.get('backup_dir', ONGOING_RAW_BACKUP_DIR)

    log_file = os.path.join(backup_dir, 'snapshot_log.{}'.format(name))
    formatted_date = datetime.datetime.now().strftime(DATE_FORMAT)
    dump_name = SNAPNAME_FORMAT.format(name, formatted_date)
    output_dir = os.path.join(backup_dir, dump_name)
    cmd.extend(['--target-dir', output_dir])
    port = int(config.get('port', DEFAULT_PORT))
    if port == 3306:
        data_dir = '/srv/sqldata'
        socket_dir = '/run/mysqld/mysqld.sock'
    elif port >= 3311 and port <= 3319:
        data_dir = '/srv/sqldata.s' + str(port)[-1:]
        socket_dir = '/run/mysqld/mysqld.s' + str(port)[-1:] + '.sock'
    elif port == 3320:
        data_dir = '/srv/sqldata.x1'
        socket_dir = '/run/mysqld/mysqld.x1.sock'
    else:
        data_dir = '/srv/sqldata.m' + str(port)[-1:]
        socket_dir = '/run/mysqld/mysqld.m' + str(port)[-1:] + '.sock'
    cmd.extend(['--datadir', data_dir])
    cmd.extend(['--socket', socket_dir])
    if 'regex' in config and config['regex'] is not None:
        cmd.extend(['--tables', config['regex']])

    if 'user' in config:
        cmd.extend(['--user', config['user']])
    if 'password' in config:
        cmd.extend(['--password', config['password']])

    return (cmd, dump_name, log_file)


def snapshot(name, config, rotate):
    """
    Perform a snapshot of the given instance,
    with the given settings. Once finished successfully, consolidate the
    number of files if asked, and move it to the "latest" dir. Archive
    any previous dump of the same name
    """
    logger = logging.getLogger('backup')
    (cmd, snapshot_name, log_file) = get_xtrabackup_cmd(name, config)
    logger.debug(cmd)

    backup_dir = config.get('backup_dir', ONGOING_RAW_BACKUP_DIR)
    output_dir = os.path.join(backup_dir, snapshot_name)

    if 'statistics' in config:  # Enable statistics gathering?
        if config['port'] == 3306:
            source = config['host']
        else:
            source = config['host'] + ':' + str(config['port'])
        stats = DatabaseBackupStatistics(dump_name=snapshot_name, section=name, type=config['type'],
                                         config=config['statistics'], backup_dir=output_dir,
                                         source=source)
    else:
        stats = DisabledBackupStatistics()

    stats.start()

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()

    # TODO: Handle xtrabackup errors

    # TODO: Backups seems ok, prepare it for recovery and cleanup

    # consolidate it to fewer files

    stats.gather_metrics()  # not sure here or below

    # compress it

    if rotate:
        # This is not a manual backup, peform rotations
        # move the old latest one to the archive, and the current as the latest
        move_dumps(name, FINAL_RAW_BACKUP_DIR, ARCHIVE_RAW_BACKUP_DIR, SNAPNAME_REGEX)
        os.rename(output_dir, os.path.join(FINAL_RAW_BACKUP_DIR, snapshot_name))

    stats.finish()
    return 0


def logical_dump(name, config, rotate):
    """
    Perform the logical backup of the given instance,
    with the given settings. Once finished successfully, consolidate the
    number of files if asked, and move it to the "latest" dir. Archive
    any previous dump of the same name
    """

    logger = logging.getLogger('backup')
    (cmd, dump_name, log_file) = get_mydumper_cmd(name, config)
    logger.debug(cmd)

    backup_dir = config.get('backup_dir', ONGOING_LOGICAL_BACKUP_DIR)
    output_dir = os.path.join(backup_dir, dump_name)
    metadata_file_path = os.path.join(output_dir, 'metadata')

    if 'statistics' in config:  # Enable statistics gathering?
        if config['port'] == 3306:
            source = config['host']
        else:
            source = config['host'] + ':' + str(config['port'])
        stats = DatabaseBackupStatistics(dump_name=dump_name, section=name, type=config['type'],
                                         config=config['statistics'], backup_dir=output_dir,
                                         source=source)
    else:
        stats = DisabledBackupStatistics()

    stats.start()

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()
    if len(out) > 0:
        sys.stdout.buffer.write(out)
    errors = err.decode("utf-8")
    if len(errors) > 0:
        logger.error('The mydumper stderr was not empty')
        sys.stderr.write(errors)

    # Check backup finished correctly
    if ' CRITICAL ' in errors:
        stats.fail()
        return 3

    with open(log_file, 'r') as output:
        log = output.read()
    if ' [ERROR] ' in log:
        stats.fail()
        return 4

    with open(metadata_file_path, 'r') as metadata_file:
        metadata = metadata_file.read()
    if 'Finished dump at: ' not in metadata:
        stats.fail()
        return 5

    # Backups seems ok, start consolidating it to fewer files
    if 'archive' in config and config['archive']:
        archive_databases(output_dir, config['threads'])

    stats.gather_metrics()

    if rotate:
        # This is not a manual backup, peform rotations
        # move the old latest one to the archive, and the current as the latest
        move_dumps(name, FINAL_LOGICAL_BACKUP_DIR, ARCHIVE_LOGICAL_BACKUP_DIR, DUMPNAME_REGEX)
        os.rename(output_dir, os.path.join(FINAL_LOGICAL_BACKUP_DIR, dump_name))

    stats.finish()
    return 0


def move_dumps(name, source, destination, regex=DUMPNAME_REGEX):
    """
    Move directories (and all its contents) from source to destination
    for all dirs that have the right format (dump.section.date) and
    section matches the given name
    """
    files = os.listdir(source)
    pattern = re.compile(regex)
    for entry in files:
        path = os.path.join(source, entry)
        if not os.path.isdir(path):
            continue
        match = pattern.match(entry)
        if match is None:
            continue
        if name == match.group(1):
            os.rename(path, os.path.join(destination, entry))


def purge_dumps(source, days, regex=DUMPNAME_REGEX):
    """
    Remove subdirectories in ARCHIVE_BACKUP_DIR and all its contents for dirs that
    have the right format (dump.section.date) and are older than the given
    number of days.
    """
    files = os.listdir(source)
    pattern = re.compile(regex)
    for entry in files:
        path = os.path.join(source, entry)
        if not os.path.isdir(path):
            continue
        match = pattern.match(entry)
        if match is None:
            continue
        timestamp = datetime.datetime.strptime(match.group(2), DATE_FORMAT)
        if (timestamp < (datetime.datetime.now() - datetime.timedelta(days=days)) and
           timestamp > datetime.datetime(2018, 1, 1)):
            shutil.rmtree(path)


def tar_and_remove(source, name, files):

    cmd = ['/bin/tar']
    tar_file = os.path.join(source, '{}.gz.tar'.format(name))
    cmd.extend(['--create', '--remove-files', '--file', tar_file, '--directory', source])
    cmd.extend(files)

    logger = logging.getLogger('backup')
    logger.debug(cmd)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()


def archive_databases(source, threads):
    """
    To avoid too many files per backup, archive each database file in
    separate tar files for given directory "source". The threads
    parameter allows to control the concurrency (number of threads executing
    tar in parallel).
    """

    files = sorted(os.listdir(source))

    schema_files = list()
    name = None
    pool = ThreadPool(threads)
    for item in files:
        if item.endswith('-schema-create.sql.gz') or item == 'metadata':
            if schema_files:
                pool.apply_async(tar_and_remove, (source, name, schema_files))
                schema_files = list()
            if item != 'metadata':
                schema_files.append(item)
                name = item.replace('-schema-create.sql.gz', '')
        else:
            schema_files.append(item)
    if schema_files:
        pool.apply_async(tar_and_remove, (source, name, schema_files))

    pool.close()
    pool.join()


def parse_options():
    parser = argparse.ArgumentParser(description=('Create a mysql/mariadb logical backup using '
                                                  'mydumper or a snapshot using mariabackup.'
                                                  'It has 2 modes: Interactive, where '
                                                  'options are received from the command line '
                                                  'and non-interactive, where it reads from a '
                                                  'config file and performs several backups'))
    parser.add_argument('section',
                        help=('Section name of the backup. E.g.: "s3", "tendril". '
                              'If section is set, --config-file is ignored. '
                              'If it is empty, only config-file options will be used '
                              'and other command line options will be ignored.'),
                        nargs='?',
                        default=None)
    parser.add_argument('--config-file',
                        help='Config file to use. By default, {} .'.format(DEFAULT_CONFIG_FILE),
                        default=DEFAULT_CONFIG_FILE)
    parser.add_argument('--host',
                        help='Host to generate the backup from. Default: {}.'.format(DEFAULT_HOST),
                        default=DEFAULT_HOST)
    parser.add_argument('--port',
                        type=int,
                        help='Port to connect to. Default: {}.'.format(DEFAULT_PORT),
                        default=DEFAULT_PORT)
    parser.add_argument('--user',
                        help='User to connect for backup. Default: {}.'.format(DEFAULT_USER),
                        default=DEFAULT_USER)
    parser.add_argument('--password',
                        help='Password used to connect. Default: empty password.',
                        default='')
    parser.add_argument('--threads',
                        type=int,
                        help=('Number of threads to use for exporting. '
                              'Default: {} concurrent threads.').format(DEFAULT_THREADS),
                        default=DEFAULT_THREADS)
    parser.add_argument('--type',
                        choices=['dump', 'snapshot'],
                        help='Backup type: dump or snapshot. Default: {}'.format(DEFAULT_TYPE),
                        default=DEFAULT_TYPE)
    parser.add_argument('--backup-dir',
                        help=('Directory where the backup will be stored. '
                              'Default: {}.').format(DEFAULT_BACKUP_DIR),
                        default=DEFAULT_BACKUP_DIR)
    parser.add_argument('--rows',
                        type=int,
                        help=('Max number of rows to dump per file. '
                              'Default: {}').format(DEFAULT_ROWS),
                        default=DEFAULT_ROWS)
    parser.add_argument('--archive',
                        action='store_true',
                        help=('If present, archive each db on its own tar file.'
                              'Default: Do not archive.'))
    parser.add_argument('--regex',
                        help=('Only backup tables matching this regular expression,'
                              'with format: database.table. Default: all tables'),
                        default=None)
    parser.add_argument('--stats-host',
                        help='Host where the statistics database is.',
                        default=None)
    parser.add_argument('--stats-port',
                        type=int,
                        help='Port where the statistics database is. Default: {}'
                        .format(DEFAULT_PORT),
                        default=DEFAULT_PORT)
    parser.add_argument('--stats-user',
                        help='User for the statistics database.',
                        default=None)
    parser.add_argument('--stats-password',
                        help='Password used for the statistics database.',
                        default=None)
    parser.add_argument('--stats-database',
                        help='MySQL schema that contains the statistics database.',
                        default=None)
    options = parser.parse_args().__dict__
    # nest --stats-X option into a hash 'statistics' if --stats-host is set and not null
    if 'stats_host' in options and options['stats_host'] is not None:
        statistics = dict()
        statistics['host'] = options['stats_host']
        del options['stats_host']
        statistics['port'] = options['stats_port']
        del options['stats_port']
        statistics['user'] = options['stats_user']
        del options['stats_user']
        statistics['password'] = options['stats_password']
        del options['stats_password']
        statistics['database'] = options['stats_database']
        del options['stats_database']
        options['statistics'] = statistics
    return options


def parse_config_file(config_path):
    """
    Reads the given config_path absolute path and returns a dictionary
    of dictionaries with section names as keys, config names as subkeys
    and values of that config as final values.
    Threads concurrency is limited based on the number of simultaneous backups.
    The file must be in yaml format, and it allows for default configurations:

    user: 'test'
    password: 'test'
    sections:
      s1:
        host: 's1-master.eqiad.wmnet'
      s2:
        host: 's2-master.eqiad.wmnet'
        archive: True
    """
    logger = logging.getLogger('backup')
    try:
        config_file = yaml.load(open(config_path))
    except yaml.YAMLError:
        logger.error('Error opening or parsing the YAML file {}'.format(config_path))
        sys.exit(1)
    if not isinstance(config_file, dict) or 'sections' not in config_file:
        logger.error('Error reading sections from file {}'.format(config_path))
        sys.exit(2)

    default_options = config_file.copy()
    # If individual thread configuration is set for each backup, it could have strange effects
    if 'threads' not in default_options:
        default_options['threads'] = DEFAULT_THREADS
    if 'port' not in default_options:
        default_options['port'] = DEFAULT_PORT
    if 'type' not in default_options:
        default_options['type'] = DEFAULT_TYPE

    del default_options['sections']

    manual_config = config_file['sections']
    if len(manual_config) > 1:
        # Limit the threads only if there is more than 1 backup
        default_options['threads'] = int(default_options['threads'] / CONCURRENT_BACKUPS)
    config = dict()
    for section, section_config in manual_config.items():
        # fill up sections with default configurations
        config[section] = section_config.copy()
        for default_key, default_value in default_options.items():
            if default_key not in config[section]:
                config[section][default_key] = default_value
    return config


def main():

    logger = logging.getLogger('backup')
    options = parse_options()
    if options['section'] is None:
        # no section name, read the config file, validate it and
        # execute it, including rotation of old dumps
        config = parse_config_file(options['config_file'])
        result = dict()
        backup_pool = ThreadPool(CONCURRENT_BACKUPS)
        for section, section_config in config.items():
            if section_config['type'] == 'dump':
                result[section] = backup_pool.apply_async(logical_dump,
                                                          (section, section_config, True))
            else:
                result[section] = backup_pool.apply_async(snapshot,
                                                          (section, section_config, True))
        backup_pool.close()
        backup_pool.join()

        if section_config['type'] == 'dump':
            purge_dumps(ARCHIVE_LOGICAL_BACKUP_DIR, RETENTION_DAYS, DUMPNAME_REGEX)
        else:
            purge_dumps(ARCHIVE_RAW_BACKUP_DIR, RETENTION_DAYS, SNAPNAME_REGEX)

        sys.exit(result[max(result, key=lambda key: result[key].get())].get())

    else:
        # a section name was given, only dump that one,
        # but perform no rotation
        if options['type'] == 'dump':
            result = logical_dump(options['section'], options, False)
        else:
            result = snapshot(options['section'], options, False)
        if 0 == result:
            logger.info('Backup {} generated correctly.'.format(options['section']))
        else:
            logger.critical('Error while performing backup of {}'.format(options['section']))
        sys.exit(result)


if __name__ == "__main__":
    main()
