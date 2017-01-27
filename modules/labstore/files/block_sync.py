#!/usr/bin/python3

import argparse
import fcntl
import os
import shlex
import subprocess
import sys


BDSYNC = '/usr/bin/bdsync'
SNAPSHOT_MGR = '/usr/local/sbin/snapshot-manager'
R_USER = 'root'


def run_remote(cmd, host):
    remote_cmd = '/usr/bin/ssh -i /root/.ssh/id_labstore {}@{} "{}"'.format(
        R_USER, host, cmd)
    return subprocess.check_call(shlex.split(remote_cmd))


def run_local(cmd):
    return subprocess.check_call(shlex.split(cmd))


def bdsync(local_device, r_host, r_vg, r_snapshot_name):
    remotenice = 10
    blocksize = 16384
    server = '/usr/bin/nice -{} {} --server'.format(remotenice, BDSYNC)
    remdata = '/usr/bin/ssh -i /root/.ssh/id_labstore {}@{} "{}"'.format(R_USER, r_host, server)
    sync_cmd = '{} --blocksize={} --remdata \'{}\' {} /dev/{}/{}' \
        .format(BDSYNC, blocksize, remdata, local_device, r_vg, r_snapshot_name)
    progress_cmd = '/usr/bin/pv -p -t -e -r -a -b'
    patch_cmd = '{} --patch={}'.format(BDSYNC, local_device)
    sync = subprocess.Popen(shlex.split(sync_cmd), stdout=subprocess.PIPE)
    progress = subprocess.Popen(shlex.split(progress_cmd),
                                stdin=sync.stdout,
                                stdout=subprocess.PIPE,
                                universal_newlines=True)
    patch = subprocess.Popen(shlex.split(patch_cmd), stdin=progress.stdout)
    patch.communicate()[0]

if __name__ == '__main__':

    if os.geteuid() != 0:
        print("Script needs to be run as root")
        sys.exit(1)

    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        'r_host',
        help='Remote host, e.g. 10.64.37.20 or labstore1004.eqiad.wmnet'
    )
    argparser.add_argument(
        'r_vg',
        help='Remote volume group, e.g. misc'
    )
    argparser.add_argument(
        'r_lv',
        help='Remote logical volume, e.g. test'
    )
    argparser.add_argument(
        'r_snapshot_name',
        help='Remote snapshot name, e.g. testsnap'
    )
    argparser.add_argument(
        'l_vg',
        help='Volume group of local device, e.g backup'
    )
    argparser.add_argument(
        'l_lv',
        help='Logical volume of local device, e.g test'
    )
    argparser.add_argument(
        'l_snapshot_name',
        help='Local snapshot name, e.g test-backup'
    )
    argparser.add_argument(
        'l_snapshot_size',
        help='Local snapshot size matching lvcreate expectations e.g. [1T|10G|100m]',
        default="1T",
    )

    args = argparser.parse_args()

    local_device = '/dev/{}/{}'.format(args.l_vg, args.l_lv)

    lock_file = open('/var/lock/{}_{}_backup.lock'.format(args.r_vg, args.r_lv, 'w+'))
    fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)

    try:
        try:
            run_local('/bin/findmnt --notruncate -P -n -c {}'.format(local_device))
            print('Local device is mounted. Operations may be unsafe')
            sys.exit(1)
        except subprocess.CalledProcessError:
            # Continue if the local device is not mounted
            pass

        # Make sure all the executables are present on remote and local
        run_remote('/usr/bin/test -e {}'.format(BDSYNC), args.r_host)
        run_remote('/usr/bin/test -e {}'.format(SNAPSHOT_MGR), args.r_host)
        run_local('/usr/bin/test -e {}'.format(SNAPSHOT_MGR))

        # Take a snapshot of the backup device on local before replicating from remote
        run_local('{} create --size {} {} {}/{} --force'.format(
            SNAPSHOT_MGR,
            args.l_snapshot_size, args.l_snapshot_name, args.l_vg, args.l_lv))

        # Snapshot state of remote logical volume to backup from
        run_remote('{} create {} {}/{} --force'.format(
            SNAPSHOT_MGR, args.r_snapshot_name, args.r_vg, args.r_lv), args.r_host)

        bdsync(local_device, args.r_host, args.r_vg, args.r_snapshot_name)

    finally:
        fcntl.flock(lock_file, fcntl.LOCK_UN)
