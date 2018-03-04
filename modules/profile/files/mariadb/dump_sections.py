#!/usr/bin/python3

import datetime
import os
import re
import shutil
import subprocess
import sys
import yaml

DEFAULT_CONFIG_FILE = '/etc/mysql/backups.cnf'
DEFAULT_THREADS = 16
DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 3306
DEFAULT_ROWS = 20000000
RETENTION_DAYS = 18
ONGOING_BACKUP_DIR = '/srv/backups/ongoing'
FINAL_BACKUP_DIR = '/srv/backups/latest'
ARCHIVE_BACKUP_DIR = '/srv/backups/archive'
DATE_FORMAT = '%Y-%m-%d--%H-%M-%S'
# FIXME: backups will stop working on Jan 1st 2100
DUMPNAME_REGEX = 'dump\.([a-z0-9\-]+)\.(20\d\d-[01]\d-[0123]\d\--\d\d-\d\d-\d\d)'
DUMPNAME_FORMAT = 'dump.{0}.{1}'  # where 0 is the section and 1 the date


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
    cmd.extend(['--rows', str(DEFAULT_ROWS)])
    log_file = os.path.join(ONGOING_BACKUP_DIR, 'log.{}'.format(name))
    cmd.extend(['--logfile', log_file])
    formatted_date = datetime.datetime.now().strftime(DATE_FORMAT)
    dump_name = DUMPNAME_FORMAT.format(name, formatted_date)
    output_dir = os.path.join(ONGOING_BACKUP_DIR, dump_name)
    cmd.extend(['--outputdir', output_dir])

    if 'threads' in config:
        threads = int(config['threads'])
    else:
        threads = DEFAULT_THREADS
    cmd.extend(['--threads', str(threads)])
    if 'host' in config:
        host = config['host']
    else:
        host = DEFAULT_HOST
    cmd.extend(['--host', host])
    if 'port' in config:
        port = int(config['port'])
    else:
        port = DEFAULT_PORT
    cmd.extend(['--port', str(port)])
    if 'regex' in config:
        cmd.extend(['--regex', config['regex']])

    if 'user' in config:
        cmd.extend(['--user', config['user']])
    if 'password' in config:
        cmd.extend(['--password', config['password']])

    return (cmd, dump_name, log_file)


def logical_dump(name, config):
    """
    Perform the logical backup of the given instance,
    with the given settings. Once finished sucesfully, consolidate the
    number of files if asked, and move it to the "latest" dir. Archive
    any previous dump of the same name
    """

    (cmd, dump_name, log_file) = get_mydumper_cmd(name, config)

    # print(cmd)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()
    if len(out) > 0:
        sys.stdout.buffer.write(out)
    errors = err.decode("utf-8")
    if len(errors) > 0:
        sys.stderr.write(errors)

    # Check backup finished correctly
    if ' CRITICAL ' in errors:
        return -1

    with open(log_file, 'r') as output:
        log = output.read()
    if ' [ERROR] ' in log:
        return 1

    output_dir = os.path.join(ONGOING_BACKUP_DIR, dump_name)
    metadata_file_path = os.path.join(output_dir, 'metadata')
    with open(metadata_file_path, 'r') as metadata_file:
        metadata = metadata_file.read()
    if 'Finished dump at: ' not in metadata:
        return 2

    # Backups seems ok, start consolidating it to fewer files

    if 'archive' in config and config['archive']:
        archive_databases(output_dir)

    # move the old latest one to the archive, and the current as the latest

    move_dumps(name, FINAL_BACKUP_DIR, ARCHIVE_BACKUP_DIR)
    os.rename(output_dir, os.path.join(FINAL_BACKUP_DIR, dump_name))

    return 0


def move_dumps(name, source, destination):
    """
    Move directories (and all its contents) from source to destination
    for all dirs that have the right format (dump.section.date) and
    section matches the given name
    """
    files = os.listdir(source)
    for entry in files:
        path = os.path.join(source, entry)
        if not os.path.isdir(path):
            continue
        pattern = re.compile(DUMPNAME_REGEX)
        match = pattern.match(entry)
        if match is None:
            continue
        if name == match.group(1):
            os.rename(path, os.path.join(destination, entry))


def rotate_dumps(source, days):
    """
    Remove subdirectories in ARCHIVE_BACKUP_DIR and all its contents for dirs that
    have the right format (dump.section.date) and are older than the given
    number of days.
    """
    files = os.listdir(source)
    for entry in files:
        path = os.path.join(source, entry)
        if not os.path.isdir(path):
            continue
        pattern = re.compile(DUMPNAME_REGEX)
        match = pattern.match(entry)
        if match is None:
            continue
        timestamp = datetime.datetime.strptime(match.group(2), DATE_FORMAT)
        if (timestamp < (datetime.datetime.now() - datetime.timedelta(days=days)) and
           timestamp > datetime.datetime(2017, 1, 1)):
            shutil.rmtree(path)


def tar_and_remove(source, name, files):

    cmd = ['/bin/tar']
    tar_file = os.path.join(source, '{}.gz.tar'.format(name))
    cmd.extend(['--create', '--remove-files', '--file', tar_file, '--directory', source])
    cmd.extend(files)

    # print(cmd)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()


def archive_databases(source):
    """
    To avoid too many files per backup, archive each database file in
    separate tar files for given directory "source".
    """

    files = sorted(os.listdir(source))

    schema_files = list()
    name = None
    for item in files:
        if item.endswith('-schema-create.sql.gz') or item == 'metadata':
            if schema_files:
                tar_and_remove(source, name, schema_files)
                schema_files = list()
            if item != 'metadata':
                schema_files.append(item)
                name = item.replace('-schema-create.sql.gz', '')
        else:
            schema_files.append(item)
    if schema_files:
        tar_and_remove(source, name, schema_files)


def main():
    config_file = yaml.load(open(DEFAULT_CONFIG_FILE))

    if 'user' in config_file:
        default_user = config_file['user']
    if 'password' in config_file:
        default_password = config_file['password']

    for name, config in config_file['sections'].items():
        if 'user' not in config:
            config['user'] = default_user
        if 'password' not in config:
            config['password'] = default_password
        logical_dump(name, config)

    rotate_dumps(ARCHIVE_BACKUP_DIR, RETENTION_DAYS)


if __name__ == "__main__":
    main()
