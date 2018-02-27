#!/usr/bin/python3

import yaml
import subprocess
import os
import datetime
import re
import shutil

DEFAULT_CONFIG_FILE = '/etc/mysql/backups.cnf'
DEFAULT_THREADS = 16
DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 3306
DEFAULT_ROWS = 20000000
RETENTION_DAYS = 18
BACKUP_DIR = '/srv/backups'
DATE_FORMAT = '%Y-%m-%dT%H:%M:%S'
# FIXME: backups will stop working on Jan 1st 2100
DUMPNAME_REGEX = 'dump\.[a-z0-9\-]+\.(20\d\d-[01]\d-[0123]\d\T\d\d:\d\d:\d\d)'
DUMPNAME_FORMAT = 'dump.{0}.{1}'  # where 0 is the section and 1 the date


def logical_dump(name, config, default_config):
    """
    Perform the logical backup of the given instance,
    with the given settings.
    """

    cmd = ['/usr/bin/mydumper']
    cmd.extend(['--compress', '--events', '--triggers', '--routines'])
    cmd.append('--rows={}'.format(DEFAULT_ROWS))
    log_file = os.path.join(BACKUP_DIR, 'log.{}'.format(name))
    cmd.append("--logfile='{}'".format(log_file))
    formatted_date = datetime.datetime.now().strftime(DATE_FORMAT)
    output_dir = os.path.join(BACKUP_DIR, DUMPNAME_FORMAT.format(name, formatted_date))
    cmd.append("--outputdir='{}'".format(output_dir))

    if 'threads' in config:
        threads = int(config['threads'])
    else:
        threads = DEFAULT_THREADS
    cmd.append('--threads={}'.format(threads))
    if 'host' in config:
        host = config['host']
    else:
        host = DEFAULT_HOST
    cmd.append('--host={}'.format(host))
    if 'port' in config:
        port = int(config['port'])
    else:
        port = DEFAULT_PORT
    cmd.append('--port={}'.format(port))
    if 'regex' in config:
        cmd.append("--regex='{}'".format(config['regex']))

    if 'user' in default_config:
        cmd.append("--user='{}'".format(default_config['user']))
    if 'password' in default_config:
        cmd.append("--password='{}'".format(default_config['password']))

    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()
    print(out, err)

    if 'archive' in config and config['archive']:
        archive_databases(output_dir)

    # TODO: Error handling and return values


def rotate_dumps(days):
    """
    Remove subdirectories in BACKUP_DIR and all its contents of for dirs that
    have the right format (dump.section.date) and are older than the given
    number of days.
    """
    files = os.listdir(BACKUP_DIR)
    for entry in files:
        path = os.path.join(BACKUP_DIR, entry)
        if not os.path.isdir(path):
            continue
        pattern = re.compile(DUMPNAME_REGEX)
        match = pattern.match(entry)
        if match is None:
            continue
        timestamp = datetime.datetime.strptime(match.group(1), DATE_FORMAT)
        if (timestamp < (datetime.datetime.now() - datetime.timedelta(days=days)) and
           timestamp > datetime.datetime(2017, 1, 1)):
            shutil.rmtree(path)


def archive_databases(dir):
    """
    To avoid too many files per backup, archive each database file in
    tar files.
    """
    # TODO: Note yet implemented
    pass


def main():
    config_file = yaml.load(open(DEFAULT_CONFIG_FILE))

    default_config = dict()
    if 'user' in config_file:
        default_config['user'] = config_file['user']
    if 'password' in config_file:
        default_config['password'] = config_file['password']

    for name, config in config_file['sections'].items():
        logical_dump(name, config, default_config)

    rotate_dumps(RETENTION_DAYS)


if __name__ == "__main__":
    main()
