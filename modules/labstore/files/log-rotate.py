#!/usr/bin/env python3

from glob import glob
from datetime import date

import argparse
import calendar
import logging
import os
import shutil
import sys


description = """
Rotate log files in a directory agnostic to source.
"""


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
    ]

    argparser.add_argument(
        '--path',
        type=str,
        help='Glob to find log directories on disk.',
        default='logs',
    )

    argparser.add_argument(
        '--end-with',
        type=str,
        help='Comma separated list of rotated logs extensions.  "." is prepended',
        default='log',
    )

    #    default=100,
    argparser.add_argument(
        '--min-rotate-size',
        type=int,
        default=0,
        help='In bytes. Default is to rotate all (even empty).',
    )

    #    default=10240000,
    argparser.add_argument(
        '--max-copytruncate',
        type=int,
        default=0,
        help='In bytes.  Default is to rotate all no matter the size.',
    )

    argparser.add_argument(
        '--tail-lines',
        type=int,
        default=10000,
        help='Lines to tail if size exceeds max-copytruncate.',
    )

    argparser.add_argument(
        '--rotation-day',
        type=str,
        default='*',
        help='Day of the week to rotate.  Default is every day. %s' % (str(dow)),
    )

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO)
    logging.debug(args)

    def in_rotation(lfile):
        """ determine if a file is part of a log rotation set
        :param lfile: str
        :return: bool
        """
        return any(map(lambda x: lfile.endswith(x), rotation_guide))

    def rotate():
        """ is today rotation day?
        :return: bool
        """
        return args.rotation_day.lower() in ['*', today().lower()]

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
        extensions = ['.' + f for f in args.end_with.split(',')]
        for file in candidate_logs:
            if any(map(file.endswith, extensions)):
                valid_logs.append(file)
        logging.debug("Found {} valid files from ".format(len(valid_logs), args.end_with))
        return valid_logs

    def process_logfile(fpath):
        """ Process an individual log file and rotation series in a directory"""

        fpath_new = fpath + rotation_guide[0]
        fpath_size = os.path.getsize(fpath)
        logging.debug("{} is {} bytes".format(fpath, fpath_size))

        if fpath_size < args.min_rotate_size:
            logging.debug('{} is too small to rotate'.format(fpath))
            return

        # Notice: given a max_copytruncate directive (size):
        # we forceably rotate (tail) logs that are larger than we are
        # willing to copytruncate safely //even if not rotation day//
        if args.max_copytruncate and fpath_size > args.max_copytruncate:

            logging.warning("{} is larger than {}".format(fpath, args.max_copytruncate))
            rotation_forward(fpath)

            with open(fpath, 'r') as f:
                tailed = tail(f, window=args.tail_lines)

            logging.debug('{} tailed to {}'.format(fpath, fpath_new))
            with open(fpath_new, 'w') as f:
                for l in tailed:
                    f.write('{}\n'.format(l))

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
        all_paths = glob(args.path)
    except OSError as e:
        logging.warning(str(e))
        argparser.print_help()
        sys.exit(1)

    valid_paths = [d for d in all_paths if os.path.isdir(d)]
    if not valid_paths:
        logging.warning('no valid path specified')
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
            except:
                logging.exception('{} failed'.format(pfull))
    logging.debug("processed {} logs".format(all_logs))

if __name__ == '__main__':
    main()
