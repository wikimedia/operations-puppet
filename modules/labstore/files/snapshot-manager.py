#!/usr/bin/python3

import argparse
import datetime
import operator
import logging
import os
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

    def run(self, cmd, shell=False):
        """Execute shell command
        :param cmd: list
        :param shell: bool
        :returns: str
        """
        logging.debug("Run: {}".format(' '.join(cmd)))
        out, error, retcode = runcmd(cmd, shell=shell)
        if error:
            logging.error(error)
        return retcode, out.decode('utf-8')

    def status(self):
        """ Get status information for a snapshot
        :returns: dict
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
        else:
            # should mean it does not exist
            param_dict = {}

        logging.debug('status: {}'.format(str(param_dict)))
        return param_dict

    def is_snapshot(self):
        """ Ensure that a logical volume is a snapshot
        The lv_attr is representative of properties for the lv.
        If it starts with an 's' it is a snapshot
        :returns: bool
        """
        meta = self.status()
        return bool(meta['lv_attr'].startswith('s'))

    def create(self, size):
        """ Create a snapshot
        :param size: str
        :returns: int
        """

        if self.status():
            logging.debug('creation aborted as {} already exists'.format(self.name))
            return 1

        cmd = [
            '/sbin/lvcreate',
            '--snapshot',
            '--size', size,
            '--name', self.name,
            '/dev/{}/{}'.format(self.vg, self.lv),
        ]

        logging.info('creating {} at {}'.format(self.name, size))
        out, retcode = self.run(cmd)

        return retcode

    def remove(self):
        """ Discard a snapshot with validation it is indeed a snapshot
        :returns: bool
        """

        if not self.status() or not self.is_snapshot():
            logging.info('{} cannot be removed'.format(self.name))
            return False

        # It is very dangerous to do removal operations
        # without explicit names set here as removal
        # aimed only at a vg can be treated as wildcard
        if not self.name or not self.vg:
            logging('{} or {} not set'.format(self.name, self.vg))
            return False

        logging.info('removing {}'.format(self.name))
        retcode, out = self.run([
            '/sbin/lvremove',
            '{}/{}'.format(self.vg, self.name),
            '--force',
        ])

        return not bool(self.status())


def main():

    argparser = argparse.ArgumentParser(
        os.path.basename(sys.argv[0]),
        description="Manage LVM2 Snapshots"
    )

    argparser.add_argument('action', help='execute this action')
    argparser.add_argument('name', help='snapshot name')
    argparser.add_argument('volume', help="logical volume source for snapshot $vg/$lv")

    argparser.add_argument(
        "--size",
        help="size matching lvcreate expectations e.g. [1T|10G|100m]",
        default="1T"
    )

    argparser.add_argument(
        "--max-age",
        help="Ensure snapshot is no older than in minutes",
        type=int,
        default=86400
    )

    argparser.add_argument(
        '--force',
        help='Forcefully execute operation where applicable',
        action='store_true'
    )

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )

    # re: making flag arguments required http://bugs.python.org/issue9694
    args = argparser.parse_args()

    def help():
        argparser.print_help()
        sys.exit(1)

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO)

    logging.debug(args)
    try:
        vg, lv = args.volume.split('/')
    except:
        logging.critical('source is a bad format {}'.format(args.volume))
        help()

    ss = LVMSnapshot(args.name, vg, lv)

    logging.debug("initial status {}".format(ss.status()))

    if args.force:
        logging.info("force is enabled")

    def status():

        status = ss.status()

        if not status:
            logging.warning('null status as {} does not exist'.format(args.name))
            sys.exit(1)

        ssorted = sorted(status.items(), key=operator.itemgetter(0))
        for value in ssorted:
            print('%s            -       %s' % (value[0], value[1]))

    def create():

        status = ss.status()
        if status:
            logging.debug('{} already exists'.format(args.name))
            creation_epoch = int(status['lv_time'].strftime('%s'))
            now = int(datetime.datetime.now().strftime('%s'))
            oldest_possible = now - args.max_age
            logging.debug('current epoch:       {}'.format(now))
            logging.debug('max age epoch:       {}'.format(oldest_possible))
            logging.debug('creation epoch:      {}'.format(creation_epoch))

            if creation_epoch < oldest_possible or args.force:
                logging.info('removing {}'.format(args.name))
                ss.remove()
            else:
                logging.info('skipping creation as snapshot exists')
                sys.exit(1)
                return

        ss.create(args.size)
        if not ss.status():
            logging.critical('failed to create {}'.format(args.name))

    def remove():

        if not ss.status():
            logging.info('{} does not exist'.format(args.name))
            sys.exit(1)

        ss.remove()
        if ss.status():
            logging.critical('{} still exists'.format(args.name))
            status()

    actions = {
        'status': status,
        'create': create,
        'remove': remove,
    }

    actions.get(args.action, help)()


if __name__ == '__main__':
    main()
