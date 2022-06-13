#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

from glob import glob
from datetime import date

import argparse
import calendar
import logging
import os
import shutil
import sys
import yaml

description = """
Rotate and truncate log files in a directory agnostic to source.

Dyanmic-ish cleanup and management of log files in a multitentant
environment where the stock logrotate is not suited.

Meant to be run daily to ensure files are not growing larger than
max_truncate_size but will only do normal rotation operations if
file is also larger than min_rotate_size and it is rotation_day.

This will be invasive if run multiple times on the same day as
there is no reliable mechanism to determined when the last rotation
has occurred.

If a '.norotate' file exists in a directory we will skip it.

Defaults are stored in the config file at /etc/logcleanup-config.yaml
"""


def die(msg):
    logging.error(msg)
    sys.exit(1)


def tail(f, window=20):
    """ Returns the last `window` lines of file `f` as a list.
    stackoverflow 136168
    :return: str
    """
    if window == 0:
        return []
    BUFSIZ = 1024
    f.seek(0, 2)
    bytes = f.tell()
    size = window + 1
    block = -1
    data = []
    while size > 0 and bytes > 0:
        if bytes - BUFSIZ > 0:
            # Seek back one whole BUFSIZ
            f.seek(block * BUFSIZ, 2)
            # read BUFFER
            data.insert(0, f.read(BUFSIZ))
        else:
            # file too small, start from begining
            f.seek(0, 0)
            # only read what was not read
            data.insert(0, f.read(bytes))
        linesFound = data[0].count('\n')
        size -= linesFound
        bytes -= BUFSIZ
        block -= 1
    return ''.join(data).splitlines()[-window:]


def truncate(file_path):
    """reduce a file to 0 while keeping inode
    :param file_path: str
    """
    with open(file_path, 'w'):
        logging.info('truncate {}'.format(file_path))


def rotate_option(lfile, rotation_guide):
    """ determine if file in rotation has a next candidate
    :param lfile: str
    :param rotation_guide: list
    :return: str or None
    """

    # if it's in rotation but there is no next stage
    if lfile[-2:] == rotation_guide[-1]:
        logging.debug("end of rotation for {}".format(lfile))
        return None

    # our next rotation file based on current
    return lfile[:-2] + rotation_guide[rotation_guide.index(lfile[-2:]) + 1]


def today():
    """ return day of week in human readable
    :return: str
    """
    # 2016-12-05
    numeric_date = date.today()
    return calendar.day_name[numeric_date.weekday()]


def set_perms(sfile, dfile, perms=0o644):
    """ - match owner/group for a src to a dst
        - establish an acl on dst
    :param sfile: str
    :param dfile: str
    :param perms: int
    """
    sfile_stat = os.stat(sfile)
    fd = os.open(dfile, os.O_RDONLY)
    os.fchown(fd, sfile_stat.st_uid, sfile_stat.st_gid)
    os.close(fd)
    os.chmod(dfile, perms)


def main():

    argparser = argparse.ArgumentParser(
        description=description,
    )

    rotation_guide = [
        '.1',
        '.2',
        '.3',
        '.4',
    ]

    dow = [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
        '*',
    ]

    argparser.add_argument(
        '--dir',
        action='append',
        help='globs to find log directories on disk',
    )

    argparser.add_argument(
        '--end-with',
        action='append',
        help='''Space separated logs extensions.  "." is prepended''',
    )

    argparser.add_argument(
        '--min-rotate-size',
        type=int,
        help='In bytes',
    )

    argparser.add_argument(
        '--max-copytruncate',
        type=int,
        help='In bytes',
    )

    argparser.add_argument(
        '--tail-lines',
        type=int,
        help='Lines to tail if size exceeds max-copytruncate',
    )

    argparser.add_argument(
        '--rotation-day',
        type=str,
        help='Day of the week to rotate. %s or "*"' % (str(dow)),
    )

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true',
    )

    argparser.add_argument(
        '--config',
        type=str,
        help='''YAML config file, arguments specified on command line will
             override config specifed in file''',
        default='/etc/logcleanup-config.yaml',
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO)

    logging.debug(args)

    try:
        with open(args.config) as f:
            config = yaml.safe_load(f)
    except IOError:
        die('reading config file  %s' % (args.config))

    # Convert Namespace object args to dict
    # Only populate keys with not None values
    cli_args = {arg: value for arg, value in vars(args).items() if value}
    config.update(cli_args)

    logging.debug(config)

    if config['rotation_day'] not in dow:
        die('Invalid day of the week %s' % (config['rotation_day']))

    required_pints = ['max_copytruncate',
                      'tail_lines',
                      'min_rotate_size']

    for p in required_pints:
        if p not in config:
            die('missing config value %s' % (p,))
        if not isinstance(config[p], int):
            die('%s is not a valid int' % (p,))

    def in_rotation(lfile):
        """ determine if a file is part of a log rotation set
        :param lfile: str
        :return: bool
        """
        return any([lfile.endswith(x) for x in rotation_guide])

    def rotate():
        """ is today rotation day?
        :return: bool
        """
        return config['rotation_day'].lower() in ['*', today().lower()]

    def rotation_forward(rotated_file):
        """ move forward (or purge) log archives based on rotation_guide

            this should be done prior to primary file rotation to avoid
            overwriting files that are currently in the rotation cycle.
        :param rotated_file: str
        """
        for end in reversed(rotation_guide):
            rotation_stage = rotated_file + end
            if os.path.exists(rotation_stage):
                logging.debug("rotation {} exists".format(rotation_stage))
                rotate = rotate_option(rotation_stage, rotation_guide)

                if rotate is None:
                    logging.debug("removing {}".format(rotation_stage))
                    os.remove(rotation_stage)
                else:
                    logging.debug("move {} to {}".format(rotation_stage, rotate))
                    os.rename(rotated_file + end, rotate)

    def rotateable(all_files):
        """ Find all files eligible for rotation
        :param all_files: list of files
        :return: list
        """

        # only consider files that do not appear to be in-rotation derivatives
        candidate_logs = [f for f in all_files if not in_rotation(f)]

        valid_logs = []
        extensions = ['.' + f for f in config['end_with']]
        for file in candidate_logs:
            if any(map(file.endswith, extensions)):
                valid_logs.append(file)
        logging.debug("Found {} valid files from {}".format(len(valid_logs), config['end_with']))
        return valid_logs

    def process_logfile(fpath):
        """ Process an individual log file and rotation series in a directory"""

        fpath_new = fpath + rotation_guide[0]
        fpath_size = os.path.getsize(fpath)
        logging.debug("{} is {} bytes".format(fpath, fpath_size))

        if fpath_size < config['min_rotate_size']:
            logging.debug('{} is too small to rotate'.format(fpath))
            return

        # Notice: given a max_copytruncate directive (size):
        # we forceably rotate (tail) logs that are larger than we are
        # willing to copytruncate safely //even if not rotation day//
        if config['max_copytruncate'] and fpath_size > config['max_copytruncate']:

            logging.warning("{} is larger than {}".format(fpath, config['max_copytruncate']))
            rotation_forward(fpath)

            with open(fpath, 'r') as f:
                tailed = tail(f, window=config['tail_lines'])

            logging.debug('{} tailed to {}'.format(fpath, fpath_new))
            with open(fpath_new, 'w') as f:
                for line in tailed:
                    f.write('{}\n'.format(line))

            set_perms(fpath, fpath_new)
            truncate(fpath)
            return

        if rotate():
            rotation_forward(fpath)
            logging.debug("rotating {} to {}".format(fpath, fpath_new))

            shutil.copy2(fpath, fpath_new)
            set_perms(fpath, fpath_new)
            truncate(fpath)

    try:
        all_paths = []
        for path in config['dir']:
            all_paths.extend(glob(path))
    except OSError as e:
        logging.warning(str(e))
        argparser.print_help()
        sys.exit(1)

    valid_paths = [d for d in all_paths if os.path.isdir(d)]
    if not valid_paths:
        logging.error('no valid path specified')
        sys.exit(1)

    logging.debug("found {} valid paths".format(len(valid_paths)))

    all_logs = 0
    for path in valid_paths:

        if os.path.exists(os.path.join(path, '.norotate')):
            logging.info("skipping {}".format(path))
            continue

        valid_logs = rotateable(os.listdir(path))
        all_logs += len(valid_logs)

        for f in valid_logs:
            pfull = os.path.join(path, f)
            logging.debug(pfull)
            try:
                process_logfile(pfull)
            except Exception:
                logging.exception('{} failed'.format(pfull))
    logging.debug("processed {} logs".format(all_logs))


if __name__ == '__main__':
    main()
