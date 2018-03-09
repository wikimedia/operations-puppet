#!/usr/bin/python3

import argparse
import os
import re
import subprocess
import sys

DEFAULT_THREADS = 16
DEFAULT_HOST = 'localhost'
DEFAULT_PORT = 3306
DEFAULT_USER = 'root'
BACKUP_DIR = '/srv/backups/latest'
# FIXME: backups will stop working on Jan 1st 2100
DUMPNAME_REGEX = 'dump\.([a-z0-9\-]+)\.(20\d\d-[01]\d-[0123]\d\--\d\d-\d\d-\d\d)'


def parse_options():
    parser = argparse.ArgumentParser(description='Recover a logical backup')
    parser.add_argument('section',
                        help=('Section name or absolute path of the directory to recover' 
                        '("s3", "/srv/backups/archive/dump.s3.2022-11-12--19-05-35")'))
    parser.add_argument('--host', help='Host to recover to', default=DEFAULT_HOST)
    parser.add_argument('--port', type=int, help='Port to recover to', default=DEFAULT_PORT)
    parser.add_argument('--user', help='User to connect for recovery', default=DEFAULT_USER)
    parser.add_argument('--password', help='Password to recover', default='')
    parser.add_argument('--socket', help='Socket to recover to', default=None)
    parser.add_argument('--database', help='Only recover this database', default=None)
    parser.add_argument('--replicate', help=('Enable binlog on import, for imports '
                        'to a master that have to be replicated (but makes load slower)'),
                        type=bool, default=False)

    return parser.parse_args()


def untar_and_remove(file_name, directory):
    cmd = ['/bin/tar']
    tar_file = os.path.join(directory, file_name)
    cmd.extend(['--extract', '--file', tar_file, '--directory', directory])

    # print(cmd)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()

    os.remove(tar_file)


def get_my_loader_cmd(backup_dir, options):
    cmd = ['/usr/bin/myloader']
    cmd.extend(['--directory', backup_dir])
    cmd.extend(['--threads', str(DEFAULT_THREADS)])
    cmd.extend(['--host', options.host])
    cmd.extend(['--port', str(options.port)])
    cmd.extend(['--user', options.user])
    cmd.extend(['--password', options.password])
    if options.socket:
        cmd.extend(['--socket', options.socket])
    if options.database:
        cmd.extend(['--source-db', options.database])
    if options.replicate:
        cmd.extend(['--enable-binlog'])
    cmd.extend(['--overwrite-tables'])

    return cmd


def recover_logical_dump(options):
    backup_name = None
    pattern = re.compile(DUMPNAME_REGEX)
    
    if options.section.startsWith('/'):
    # Recover from absolute path
        match = pattern.match(options.section)
        if os.path.isdir(options.section) and match is not None:
            backup_name = match.group(0)
            backup_dir = options.section
    else:
    # Recover from default dir
        files = sorted(os.listdir(BACKUP_DIR), reverse=True)

        for entry in files:
            path = os.path.join(BACKUP_DIR, entry)
            if not os.path.isdir(path):
                continue
            match = pattern.match(entry)
            if match is None:
                continue
            if options.section == match.group(1):
                backup_name = match.group(0)
                backup_dir = path
                break

    if backup_name is None:
        print('Latest backup with name "{}" not found'.format(options.section))
        return -1

    print('Attempting to recover "{}" ...'.format(backup_name))
    # untar any files
    if options.database:
        db_tar_name = '{}.gz.tar'.format(options.database)
        print('Unarchiving {} ...'.format(db_tar_name))
        if os.path.isfile(os.path.join(backup_dir, db_tar_name)):
            untar_and_remove(db_tar_name, backup_dir)
    else:
        print('Unarchiving consolidated databases...')
        files = os.listdir(backup_dir)
        for entry in files:
            # TODO: serial unarchiving still, could be too slow
            if entry.endswith('.tar'):
                untar_and_remove(entry, backup_dir)
    # run myloader
    print('Running myloader...')
    cmd = get_my_loader_cmd(backup_dir, options)

    # print(cmd)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.Popen.wait(process)
    out, err = process.communicate()

    if len(out) > 0:
        sys.stdout.buffer.write(out)
    if len(err) > 0:
        sys.stderr.write(err.decode("utf-8"))
        return 1
    return 0


def main():
    options = parse_options()
    recover_logical_dump(options)


if __name__ == "__main__":
    main()
