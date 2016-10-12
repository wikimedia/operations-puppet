#!/usr/bin/python3

import argparse
import datetime
import logging
import os
import re
import sys
import subprocess

from dateutil.parser import parse

def runcmd(command, cwd=None, stdin=None, shell=True):
    """ Run a command
    :param command: str
    :param cwd: str
    :param stdin: str
    :param shell: bool
    :return: tuple
    """
    p = subprocess.Popen(
        command,
        shell=shell,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    (out, error) = p.communicate(input=stdin)
    retcode = p.wait()
    return out, error, retcode


class LVMSnapshot:
    def __init__(self, name, vg, lv):
        self.name = name
        self.lv = lv
        self.vg = vg
        self.source = '{}/{}'.format(vg, lv)

    def run(self, cmd, shell=False):
        """Execute shell command
        :param cmd: list
        :param shell: bool
        :returns: str
        """
        out, error, retcode = runcmd(cmd, shell=shell)
        return retcode, out.decode('utf-8')

    def status(self):
        """ Get status information for a snapshot
        :returns: dict
        :note: returns {'lv_name': ''} for non-existent snapshot
        """
        params = [
            'lv_name',
            'lv_path',
            'lv_attr',
            'lv_size',
            'lv_time',
            'origin',
            'snap_percent'
        ]

        status = [
            '/sbin/lvs',
            '--noheadings',
            '--select',
            'lv_name={}'.format(self.name),
            '-o',
            ','.join(params),
            "--separator=';'",
        ]

        # if lvname does not exist will still exit 0
        retcode, out = self.run(status)
        if retcode:
            return {}

        param_values = [x.strip().strip("'") for x in out.split(';')]
        param_dict = dict(zip(params, param_values))

        if 'lv_time' in param_dict:
            param_dict['lv_time'] = parse(param_dict['lv_time'])
        return param_dict

    def is_snapshot(self):
        """ Ensure that a logical volume is a snapshot
        The lv_attr is representative of properties for the lv.
        If it starts with an 's' it is a snapshot
        :returns: bool
        """
        meta = self.status()
        return bool(re.match('s', meta['lv_attr']))

    def create(self, size):
        """ Create a snapshot
        :param size: str
        :returns: int
        """

        if self.exists():
            return 1

        cmd = [
            '/sbin/lvcreate',
            '--snapshot',
            '--size', size,
            '--name', self.name,
            '/dev/{}/{}'.format(self.vg, self.lv),
        ]

        out, retcode = self.run(cmd)
        return retcode

    def exists(self):
        return bool('lv_path' in self.status())

    def remove(self):

        if not self.exists() or not self.is_snapshot():
           return False

        # It is very dangerous to do removal operations
        # without explicit names set here as removal
        # aimed only at a vg can be treated as wildcard
        if not self.name or not self.vg:
            return False

        retcode, out = self.run([
            '/sbin/lvremove',
            '{}/{}'.format(self.vg, self.name),
            '--force',
        ])

        return not self.exists()


def main():
    argparser = argparse.ArgumentParser(
        os.path.basename(sys.argv[0]),
        description="Manage LVM2 Snapshots"
    )

    argparser.add_argument(
        "--action",
        help="LVM execution",
        default="status"
    )

    argparser.add_argument(
        "--name",
        help="snapshot name",
        default=""
    )

    argparser.add_argument(
        "--size",
        help="size matching lvcreate expectations e.g. [1T|10G|100m]",
        default="1T"
    )

    argparser.add_argument(
        "--source",
        help="Path to a source device e.g. $vg/$lv",
        default=""
    )

    argparser.add_argument(
        "--force",
        help="Force operation regardless of current state",
        type=bool,
        default=False
    )

    argparser.add_argument(
        "--max-age",
        help="Ensure snapshot is no older than in minutes",
        type=int,
        default=86400
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

    try:
        vg, lv = args.source.split('/')
    except:
        logging.critical('source is a bad format {}'.format(args.source))
        argparser.print_help()
        sys.exit(1)

    ss = LVMSnapshot(args.name, vg, lv)

    logging.debug("initial status {}".format(ss.status()))

    if args.force:
        logging.debug("force is enabled")

    def status():
        status = ss.status()


        for key, status in ss.status().items():
            print('%10s - %3s' % (key, status))

    def create():

        if ss.exists():
            state = ss.status()
            creation_epoch = int(state['lv_time'].strftime('%s'))
            now = int(datetime.datetime.now().strftime('%s'))
            oldest_possible = now - args.max_age

            if creation_epoch < oldest_possible or args.force:
                logging.debug('removing {}'.format(args.name))
                ss.remove()
            logging.info('skipping creation as snapshot exists')
            return

        ss.create(args.size)
        status()

    def remove():
        if not ss.exists():
            logging.info('{} does not exist'.format(args.name))
        ss.remove()
        status()

    actions = {
        'status' : status,
        'create' : create,
        'remove' : remove,
    }

    actions[args.action]()
    sys.exit(0)


if __name__ == '__main__':
    main()
