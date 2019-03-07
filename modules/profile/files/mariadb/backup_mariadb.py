#!/usr/bin/python3

# Dependencies: python3 python3-pymysql python3-yaml
#               mydumper at /usr/bin/mydumper (if dumps are used)
#               wmf-mariadb101 (for /opt/wmf-mariadb101/bin/mariabackup, if snapshoting is used)
#               pigz on /usr/bin/pigz (if snapshoting is used)
#               tar at /bin/tar
#               TLS certificate installed at /etc/ssl/certs/Puppet_Internal_CA.pem (if data
#               gathering metrics are used)

import argparse
import datetime
import logging
from multiprocessing.pool import ThreadPool
import os
import pymysql
import shutil
import socket
import subprocess
import sys
import re
import yaml

DEFAULT_CONFIG_FILE = '/etc/mysql/backups.cnf'
DEFAULT_THREADS = 18
DEFAULT_TYPE = 'dump'
CONCURRENT_BACKUPS = 2
DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 3306
DEFAULT_ROWS = 20000000
DEFAULT_USER = 'root'

DEFAULT_BACKUP_DIR = '/srv/backups'

DUMPNAME_FORMAT = 'dump.{0}.{1}'  # where 0 is the section and 1 the date
SNAPNAME_FORMAT = 'snapshot.{0}.{1}'  # where 0 is the section and 1 the date

DEFAULT_BACKUP_PATH = '/srv/backups'
ONGOING_BACKUP_DIR = 'ongoing'
FINAL_BACKUP_DIR = 'latest'
ARCHIVE_BACKUP_DIR = 'archive'
DATE_FORMAT = '%Y-%m-%d--%H-%M-%S'
DEFAULT_BACKUP_TYPE = 'dump'
DEFAULT_BACKUP_THREADS = 18
DEFAULT_RETENTION_DAYS = 18

TLS_TRUSTED_CA = '/etc/ssl/certs/Puppet_Internal_CA.pem'


class BackupStatistics:
    """
    Virtual class that defines the interface to generate
    and store the backup statistics.
    """

    def __init__(self, dir_name, section, type, source, backup_dir, config):
        self.dump_name = dir_name
        self.section = section
        self.type = type
        self.source = source
        self.backup_dir = backup_dir

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
    host = None
    port = 3306
    user = None
    password = None

    def __init__(self, dir_name, section, type, source, backup_dir, config):
        self.dump_name = dir_name
        self.section = section
        if source.endswith(':3306'):
            self.source = source[:-5]
        else:
            self.source = source
        self.backup_dir = backup_dir
        self.host = config.get('host', DEFAULT_HOST)
        self.port = config.get('port', DEFAULT_PORT)
        self.database = config['database']
        self.user = config.get('user', DEFAULT_USER)
        self.password = config['password']
        self.type = type

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
                query = "SELECT id, status FROM backups WHERE name = %s and status = 'ongoing'"
                try:
                    result = cursor.execute(query, (self.dump_name, ))
                except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                    logger.error('A MySQL error occurred while finding the entry for the '
                                 'backup')
                    return False
                if result is None:
                    logger.error('We could not select the database backup statistics server')
                    return False
                data = cursor.fetchall()
                if len(data) != 1:
                    logger.error('We could not find a single statistics entry for a non-ongoing '
                                 'dump'.format(status))
                    return False
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

    def recursive_file_traversal(self, db, backup_id, top_dir, directory):
        """
        Traverses 'directory' and its subdirs (assuming top_dir is the absolute starting path),
        inserts metadata on database 'db',
        and returns the total size of the directory, or None if there was an error.
        """
        logger = logging.getLogger('backup')
        total_size = 0
        # TODO: capture file errors
        for name in sorted(os.listdir(os.path.join(top_dir, directory))):
            path = os.path.join(top_dir, directory, name)
            statinfo = os.stat(path)
            size = statinfo.st_size
            total_size += size
            time = statinfo.st_mtime
            # TODO: Identify which object this files corresponds to and record it on
            #       backup_objects
            with db.cursor(pymysql.cursors.DictCursor) as cursor:
                query = ("INSERT INTO backup_files "
                         "(backup_id, file_path, file_name, size, file_date, backup_object_id) "
                         "VALUES (%s, %s, %s, %s, FROM_UNIXTIME(%s), NULL)")
                try:
                    cursor.execute(query, (backup_id, directory, name, size, time))
                except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
                    logger.error('A MySQL error occurred while inserting the backup '
                                 'file details')
                    return None
            # traverse subdir
            # TODO: Check for links to avoid infinite recursivity
            if os.path.isdir(path):
                dir_size = self.recursive_file_traversal(db,
                                                         backup_id,
                                                         top_dir,
                                                         os.path.join(directory, name))
                if dir_size is None:
                    return None
                else:
                    total_size += dir_size
        return total_size

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
            query = "SELECT id, status FROM backups WHERE name = %s AND status = 'ongoing'"
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

        # Insert the backup file list
        total_size = self.recursive_file_traversal(db=db, backup_id=backup_id,
                                                   top_dir=self.backup_dir, directory='')
        if total_size is None:
            logger.error('An error occurred while traversing the individual backup files')
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


class NullBackup:

    config = dict()

    def __init__(self, config, backup):
        """
        Initialize commands
        """
        self.config = config
        self.backup = backup
        self.logger = backup.logger

    def get_backup_cmd(self, backup_dir):
        """
        Return list with binary and options to execute to generate a new backup at backup_dir
        """
        return '/bin/true'

    def get_prepare_cmd(self, backup_dir):
        """
        Return list with binary and options to execute to prepare an existing backup. Return
        none if prepare is not necessary (nothing will be executed in that case).
        """
        return ''

    def errors_on_output(self, stdout, stderr):
        """
        Returns true if there were errors on the output of the backup command. As parameters,
        a string containing the standard output and standard error ouput of the backup command.
        Return False if there were not detected errors.
        """
        return False

    def errors_on_log(self, log_file):
        """
        Returns true if there were errors on the log of the backup command. As a parameter,
        a string containing the full path of the log file.
        Return False if there were not detected errors.
        """
        return False

    def errors_on_metadata(self, backup_dir):
        """
        Checks the metadata file of a backup, and sees if it has the right format and content.
        As a parameter, a string containing the full path of the metadata file.
        Returns False if tehre were no detected errors.
        """
        return False

    def errors_on_prepare(self, stdout, stderr):
        return False


class MariaBackup(NullBackup):

    xtrabackup_path = '/opt/wmf-mariadb101/bin/mariabackup'  # FIXME for global path after upgrade
    xtrabackup_prepare_memory = '10G'

    def get_backup_cmd(self, backup_dir):
        """
        Given a config, returns a command line for mydumper, the name
        of the expected snapshot, and the log path.
        """
        cmd = [self.xtrabackup_path, '--backup']

        output_dir = os.path.join(backup_dir, self.backup.dir_name)
        cmd.extend(['--target-dir', output_dir])
        port = int(self.config.get('port', DEFAULT_PORT))
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
        if 'regex' in self.config and self.config['regex'] is not None:
            cmd.extend(['--tables', self.config['regex']])

        if 'user' in self.config:
            cmd.extend(['--user', self.config['user']])
        if 'password' in self.config:
            cmd.extend(['--password', self.config['password']])

        return cmd

    def errors_on_metadata(self, backup_dir):
        metadata_file = os.path.join(backup_dir, self.backup.dir_name, 'xtrabackup_info')
        try:
            with open(metadata_file, 'r', errors='ignore') as metadata_file:
                metadata = metadata_file.read()
        except OSError:
            return False
        if 'end_time = ' not in metadata:
            return True
        return False

    def _get_xtraback_prepare_cmd(self, backup_dir):
        """
        Returns the command needed to run the backup prepare
        (REDO and UNDO actions to make the backup consistent)
        """
        path = os.path.join(backup_dir, self.backup.dir_name)
        cmd = [self.xtrabackup_path, '--prepare']
        cmd.extend(['--target-dir', path])
        # TODO: Make the amount of memory configurable
        # WARNING: apparently, --innodb-buffer-pool-size fails sometimes
        cmd.extend(['--use-memory', self.xtrabackup_prepare_memory])

        return cmd

    def errors_on_output(self, stdout, stderr):
        errors = stderr.decode("utf-8")
        if 'completed OK!' not in errors:
            sys.stderr.write(errors)
            return True
        return False

    def errors_on_log(self, log_file):
        return False

    def get_prepare_cmd(self, backup_dir):
        """
        Once an xtrabackup backup has completed, run prepare so it is ready to be copied back
        """
        cmd = self._get_xtraback_prepare_cmd(backup_dir)
        return cmd

    def errors_on_prepare(self, stdout, stderr):
        return self.errors_on_output(stdout, stderr)

    def archive_databases(self, source, threads):
        # FIXME: Allow database archiving for xtrabackup
        pass


class MyDumperBackup(NullBackup):

    rows = 20000000

    def get_backup_cmd(self, backup_dir):
        """
        Given a config, returns a command line for mydumper, the name
        of the expected dump, and the log path.
        """
        # FIXME: even if there is not privilege escalation (everybody can run
        # mydumper and parameters are gotten from a localhost file),
        # check parameters better to avoid unintended effects
        cmd = ['/usr/bin/mydumper']
        cmd.extend(['--compress', '--events', '--triggers', '--routines'])

        cmd.extend(['--logfile', self.backup.log_file])
        output_dir = os.path.join(backup_dir, self.backup.dir_name)
        cmd.extend(['--outputdir', output_dir])

        rows = int(self.backup.config.get('rows', self.rows))
        cmd.extend(['--rows', str(rows)])
        cmd.extend(['--threads', str(self.backup.config['threads'])])
        host = self.backup.config.get('host', DEFAULT_HOST)
        cmd.extend(['--host', host])
        port = int(self.backup.config.get('port', DEFAULT_PORT))
        cmd.extend(['--port', str(port)])
        if 'regex' in self.backup.config and self.backup.config['regex'] is not None:
            cmd.extend(['--regex', self.backup.config['regex']])

        if 'user' in self.backup.config:
            cmd.extend(['--user', self.backup.config['user']])
        if 'password' in self.backup.config:
            cmd.extend(['--password', self.backup.config['password']])

        return cmd

    def get_prepare_cmd(self, backup_dir):
        return ''

    def errors_on_metadata(self, backup_dir):
        metadata_file = os.path.join(backup_dir, self.backup.dir_name, 'metadata')
        try:
            with open(metadata_file, 'r', errors='ignore') as metadata_file:
                metadata = metadata_file.read()
        except OSError:
            return True
        if 'Finished dump at: ' not in metadata:
            return True
        return False

    def archive_databases(self, source, threads):
        """
        To avoid too many files per backup output, archive each database file in
        separate tar files for given directory "source". The threads
        parameter allows to control the concurrency (number of threads executing
        tar in parallel).
        """

        # TODO: Ignore already archived databases, so a second run is idempotent
        files = sorted(os.listdir(source))

        schema_files = list()
        name = None
        pool = ThreadPool(threads)
        for item in files:
            if item.endswith('-schema-create.sql.gz') or item == 'metadata':
                if schema_files:
                    pool.apply_async(self.backup.tar_and_remove, (source, name, schema_files))
                    schema_files = list()
                if item != 'metadata':
                    schema_files.append(item)
                    name = item.replace('-schema-create.sql.gz', '.gz.tar')
            else:
                schema_files.append(item)
        if schema_files:
            pool.apply_async(self.backup.tar_and_remove, (source, name, schema_files))

        pool.close()
        pool.join()

    def errors_on_output(self, stdout, stderr):
        errors = stderr.decode("utf-8")
        if ' CRITICAL ' in errors:
            return 3

    def errors_on_log(self, log_file):
        try:
            with open(log_file, 'r') as output:
                log = output.read()
        except OSError:
            return True
        if ' [ERROR] ' in log:
            return True

    def errors_on_prepare(self, stdout, stderr):
        return False


class WMFBackup:
    """
    Backup generation and handling class (preparation, rotation, archiving, compression, etc.)
    """
    name = None  # e.g. s1, tendril, s4-test
    config = {}  # dictionary with backup config (type, backup_dir, ...)
    logger = None  # object of clas logging
    dir_name = None  # e.g. dump.s1.2019-01-01--11-34-45
    file_name = None  # e.g. dump.s1.2019-01-01--11-34-45.tar.gz
    log_file = None  # e.g. /srv/backups/dumps/dump_log.s1

    @property
    def default_ongoing_backup_dir(self):
        return os.path.join(DEFAULT_BACKUP_PATH, self.config['type'] + 's', ONGOING_BACKUP_DIR)

    @property
    def default_final_backup_dir(self):
        return os.path.join(DEFAULT_BACKUP_PATH, self.config['type'] + 's', FINAL_BACKUP_DIR)

    @property
    def default_archive_backup_dir(self):
        return os.path.join(DEFAULT_BACKUP_PATH, self.config['type'] + 's', ARCHIVE_BACKUP_DIR)

    @property
    def name_regex(self):
        return self.config['type'] + \
               r'\.([a-z0-9\-]+)\.(20\d\d-[01]\d-[0123]\d\--\d\d-\d\d-\d\d)(\.[a-z0-9\.]+)?'

    def generate_file_name(self, backup_dir):
        formatted_date = datetime.datetime.now().strftime(DATE_FORMAT)
        self.dir_name = '{}.{}.{}'.format(self.config['type'], self.name, formatted_date)
        if self.config.get('compress', False):
            extension = '.tar.gz'
        else:
            extension = ''
        self.file_name = self.dir_name + extension
        self.log_file = os.path.join(backup_dir, '{}_log.{}'.format(self.config['type'], self.name))

    def find_backup_file(self, backup_dir):
        """
        Generates the backup name and returns the log path of the only backup file/dir within
        backup_dir patch of the correct name and type.
        If there is none or more than one, log an error and return None.
        """
        type = self.config['type']
        name = self.name
        # TODO: Use regex instead? Or make compulsory a full name?
        try:
            potential_files = [f for f in os.listdir(backup_dir) if f.startswith('.'.join([type,
                                                                                           name,
                                                                                           '']))]
        except FileNotFoundError:  # noqa: F821
            self.logger.error('{} directory not found'.format(backup_dir))
            return None
        if len(potential_files) != 1:
            msg = 'Expecting 1 matching {} for {}, found {}'
            self.logger.error(msg.format(type, name, len(potential_files)))
            return None
        self.dir_name = potential_files[0]
        if self.config.get('compress', False):
            extension = '.tar.gz'
        else:
            extension = ''
        self.file_name = self.dir_name + extension
        self.log_file = os.path.join(backup_dir, '{}_log.{}'.format(type, name))
        return 0

    def move_backups(self, name, source, destination, regex):
        """
        Move directories (and all its contents) from source to destination
        for all dirs that have the right format (dump.section.date) and
        section matches the given name
        """
        files = os.listdir(source)
        pattern = re.compile(regex)
        for entry in files:
            match = pattern.match(entry)
            if match is None:
                continue
            if name == match.group(1):
                self.logger.debug('Archiving {}'.format(entry))
                path = os.path.join(source, entry)
                os.rename(path, os.path.join(destination, entry))

    def purge_backups(self, source=None, days=None, regex=None):
        """
        Remove subdirectories in source dir and all its contents for dirs/files that
        have the right format (dump.section.date), its sections matches the current
        section, and are older than the given
        number of days.
        """
        if source is None:
            source = self.default_archive_backup_dir
        if days is None:
            days = self.config['retention']
        if regex is None:
            regex = self.name_regex
        files = os.listdir(source)
        pattern = re.compile(regex)
        for entry in files:
            path = os.path.join(source, entry)
            match = pattern.match(entry)
            if match is None:
                continue
            if self.name != match.group(1):
                continue
            timestamp = datetime.datetime.strptime(match.group(2), DATE_FORMAT)
            if (timestamp < (datetime.datetime.now() - datetime.timedelta(days=days)) and
               timestamp > datetime.datetime(2018, 1, 1)):
                self.logger.debug('purging backup {}'.format(path))
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)

    def tar_and_remove(self, source, name, files, compression=None):

        cmd = ['/bin/tar']
        tar_file = os.path.join(source, '{}'.format(name))
        cmd.extend(['--create', '--remove-files', '--file', tar_file, '--directory', source])
        if compression is not None:
            cmd.extend(['--use-compress-program', compression])
        cmd.extend(files)

        self.logger.debug(cmd)
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        subprocess.Popen.wait(process)
        out, err = process.communicate()

    def run(self):
        """
        Perform a backup of the given instance,
        with the given config. Once finished successfully, consolidate the
        number of files if asked, and move it to the "latest" dir. Archive
        any previous dump of the same name, if required.
        """
        type = self.config.get('type', DEFAULT_BACKUP_TYPE)
        backup_dir = self.config.get('backup_dir', self.default_ongoing_backup_dir)
        archive = self.config.get('archive', False)
        only_postprocess = self.config.get('only_postprocess', False)
        compress = self.config.get('compress', False)
        rotate = self.config.get('rotate', False)
        threads = self.config.get('threads', DEFAULT_BACKUP_THREADS)

        # find or generate the backup file/dir
        if only_postprocess:
            self.find_backup_file(backup_dir)
            if self.file_name is None:
                msg = 'Problem while trying to find the backup files at {}'
                self.logger.error(msg.format(backup_dir))
                return 10
        else:
            self.generate_file_name(backup_dir)

        output_dir = os.path.join(backup_dir, self.dir_name)
        if type == 'dump':
            backup = MyDumperBackup(self.config, self)
        elif type == 'snapshot':
            backup = MariaBackup(self.config, self)
        elif type == 'null':
            backup = NullBackup(self.config, self)
        else:
            self.logger.error('Unrecognized backup format: {}'.format(type))
            return 11

        # get the backup command
        if not only_postprocess:
            cmd = backup.get_backup_cmd(backup_dir)

        # start status monitoring
        if 'statistics' in self.config:  # Enable statistics gathering?
            source = self.config.get('host', 'localhost') + \
                     ':' + \
                     str(self.config.get('port', DEFAULT_PORT))
            stats = DatabaseBackupStatistics(dir_name=self.dir_name, section=self.name,
                                             type=type, config=self.config.get('statistics'),
                                             backup_dir=output_dir, source=source)
        else:
            stats = DisabledBackupStatistics()

        stats.start()

        if not only_postprocess:
            # run backup command
            self.logger.debug(cmd)
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            subprocess.Popen.wait(process)
            out, err = process.communicate()
            if backup.errors_on_output(out, err):
                stats.fail()
                return 3

        # Check medatada file exists and containg the finish date
        if backup.errors_on_metadata(backup_dir):
            self.logger.error('Incorrect metadata file')
            stats.fail()
            return 5

        # Backups seems ok, prepare it for recovery and cleanup
        cmd = backup.get_prepare_cmd(backup_dir)
        if cmd != '':
            self.logger.debug(cmd)
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            subprocess.Popen.wait(process)
            out, err = process.communicate()
            if backup.errors_on_prepare(out, err):
                self.logger.error('The mariabackup prepare process did not complete successfully')
                stats.fail()
                return 6

        # get file statistics
        stats.gather_metrics()

        if archive:
            backup.archive_databases(output_dir, threads)

        if compress:
            # no consolidation per-db, just compress the whole thing
            self.tar_and_remove(backup_dir, self.file_name, [self.dir_name, ],
                                compression='/usr/bin/pigz -p {}'.format(threads))

        if rotate:
            # perform rotations
            # move the old latest one to the archive, and the current as the latest
            # then delete old backups of the same section, according to the retention
            # config
            self.move_backups(self.name, self.default_final_backup_dir,
                              self.default_archive_backup_dir, self.name_regex)
            os.rename(os.path.join(backup_dir, self.file_name),
                      os.path.join(self.default_final_backup_dir, self.file_name))
            self.purge_backups()

        # we are done
        stats.finish()
        return 0

    def __init__(self, name, config):
        """
        Constructor requires the dictionary with the backup configuration, the name of the backup
        """
        self.name = name
        self.config = config
        if 'type' not in config:
            self.config['type'] = DEFAULT_BACKUP_TYPE
        self.logger = logging.getLogger(name)
        if 'retention' not in config:
            self.config['retention'] = DEFAULT_RETENTION_DAYS


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
    parser.add_argument('--only-postprocess',
                        action='store_true',
                        help=('If present, only postprocess and perform the metadata '
                              'gathering metrics for the given ongoing section backup, '
                              'skipping the actual backup. Default: Do the whole process.'))
    parser.add_argument('--rotate',
                        action='store_true',
                        help=('If present, run the rotation process, by moving it to the standard.'
                              '"latest" backup. Default: Do not rotate.'))
    parser.add_argument('--retention',
                        type=int,
                        help=('If rotate is set, purge backups of this section older than '
                              'the given value, in days. Default: 18 days.'))
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
                        help=('If present, archive each db on its own tar file.'))
    parser.add_argument('--compress',
                        action='store_true',
                        help=('If present, compress everything into a tar.gz.'
                              'Default: Do not compress.'))
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
        return
    except FileNotFoundError:  # noqa: F821
        logger.error('File {} not found'.format(config_path))
        sys.exit(2)
    if not isinstance(config_file, dict) or 'sections' not in config_file:
        logger.error('Error reading sections from file {}'.format(config_path))
        sys.exit(2)

    default_options = config_file.copy()
    # If individual thread configuration is set for each backup, it could have strange effects
    if 'threads' not in default_options:
        default_options['threads'] = DEFAULT_THREADS

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

    logging.basicConfig(filename='debug.log', level=logging.DEBUG)
    logger = logging.getLogger('backup')

    options = parse_options()
    if options['section'] is None:
        # no section name, read the config file, validate it and
        # execute it, including rotation of old dumps
        config = parse_config_file(options['config_file'])
        backup = dict()
        result = dict()
        backup_pool = ThreadPool(CONCURRENT_BACKUPS)
        for section, section_config in config.items():
            backup[section] = WMFBackup(section, section_config)
            result[section] = backup_pool.apply_async(backup[section].run)

        backup_pool.close()
        backup_pool.join()

        sys.exit(result[max(result, key=lambda key: result[key].get())].get())

    else:
        # a section name was given, only dump that one
        backup = WMFBackup(options['section'], options)
        result = backup.run()
        if 0 == result:
            logger.info('Backup {} generated correctly.'.format(options['section']))
        else:
            logger.critical('Error while performing backup of {}'.format(options['section']))
        sys.exit(result)


if __name__ == "__main__":
    main()
