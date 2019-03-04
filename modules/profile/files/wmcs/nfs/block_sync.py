#!/usr/bin/python3

import argparse
import fcntl
import logging
import os
import shlex
import subprocess
import sys

BDSYNC = "/usr/bin/bdsync"
SNAPSHOT_MGR = "/usr/local/sbin/snapshot-manager"


def run_remote(cmd, r_host, r_user):
    """ Run command on remote host over ssh
    :param cmd: Command to run
    :param r_host: Remote host to connect to
    :param r_user: Remote user to run command as
    :return returncode on success
    :raise CalledProcessError
    """
    remote_cmd = '/usr/bin/ssh -i /root/.ssh/id_labstore {}@{} "{}"'.format(
        r_user, r_host, cmd
    )
    return subprocess.check_call(shlex.split(remote_cmd))


def run_local(cmd):
    """ Run command locally
    :param cmd: Command to run_local
    :return returncode on success
    :raise CalledProcessError
    """
    return subprocess.check_call(shlex.split(cmd))


def bdsync(local_device, r_host, r_vg, r_snapshot_name, r_user):
    """ Run the block device sync from remote to local device using bdsync

    :param local_device Local device to sync to
    :param r_host Remote host to sync from
    :param r_vg Remote volume group
    :param r_snapshot_name Name of remote snapshot to sync from
    :param r_user Username to run remote commands as
    :return return code of bdsync command
    :rtype int
    """
    remotenice = 10
    blocksize = 16384
    server = "/usr/bin/nice -{} {} --server".format(remotenice, BDSYNC)
    remdata = '/usr/bin/ssh -i /root/.ssh/id_labstore {}@{} "{}"'.format(
        r_user, r_host, server
    )
    sync_cmd = "{} --blocksize={} --remdata '{}' {} /dev/{}/{}".format(
        BDSYNC, blocksize, remdata, local_device, r_vg, r_snapshot_name
    )
    progress_cmd = "/usr/bin/pv -p -t -e -r -a -b"
    patch_cmd = "{} --patch={}".format(BDSYNC, local_device)
    sync = subprocess.Popen(shlex.split(sync_cmd), stdout=subprocess.PIPE)
    progress = subprocess.Popen(
        shlex.split(progress_cmd),
        stdin=sync.stdout,
        stdout=subprocess.PIPE,
        universal_newlines=True,
    )
    patch = subprocess.Popen(shlex.split(patch_cmd), stdin=progress.stdout)
    patch.communicate()[0]
    return patch.returncode


def main():
    if os.geteuid() != 0:
        logging.error("Script needs to be run as root")
        sys.exit(1)

    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        "r_host", help="Remote host, e.g. 10.64.37.20 or labstore1004.eqiad.wmnet"
    )
    argparser.add_argument("r_vg", help="Remote volume group, e.g. misc")
    argparser.add_argument("r_lv", help="Remote logical volume, e.g. test")
    argparser.add_argument(
        "r_snapshot_name", help="Remote snapshot name, e.g. testsnap"
    )
    argparser.add_argument("l_vg", help="Volume group of local device, e.g backup")
    argparser.add_argument("l_lv", help="Logical volume of local device, e.g test")
    argparser.add_argument(
        "l_snapshot_name", help="Local snapshot name, e.g test-backup"
    )
    argparser.add_argument(
        "l_snapshot_size",
        help="Local snapshot size matching lvcreate expectations e.g. [1T|10G|100m]",
        default="1T",
    )
    argparser.add_argument(
        "--r_user", help="Remote user to run commands over ssh as", default="root"
    )
    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    args = argparser.parse_args()

    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.WARNING,
    )

    logging.debug(args)

    local_device = "/dev/{}/{}".format(args.l_vg, args.l_lv)

    lock_file = open("/var/lock/{}_{}_backup.lock".format(args.r_vg, args.r_lv), "w+")
    fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)

    try:
        try:
            run_local("/bin/findmnt --notruncate -P -n -c {}".format(local_device))
            logging.error("Local device is mounted. Operations may be unsafe")
            sys.exit(1)
        except subprocess.CalledProcessError:
            # Continue if the local device is not mounted
            pass

        # Make sure all the executables are present on remote and local
        run_remote("/usr/bin/test -e {}".format(BDSYNC), args.r_host, args.r_user)
        run_remote("/usr/bin/test -e {}".format(SNAPSHOT_MGR), args.r_host, args.r_user)
        run_local("/usr/bin/test -e {}".format(BDSYNC))
        run_local("/usr/bin/test -e {}".format(SNAPSHOT_MGR))

        # Take a snapshot of the backup device on local before replicating from remote
        run_local(
            "{} create --size {} {} {}/{} --force".format(
                SNAPSHOT_MGR,
                args.l_snapshot_size,
                args.l_snapshot_name,
                args.l_vg,
                args.l_lv,
            )
        )

        # Snapshot state of remote logical volume to backup from
        run_remote(
            "{} create {} {}/{} --force".format(
                SNAPSHOT_MGR, args.r_snapshot_name, args.r_vg, args.r_lv
            ),
            args.r_host,
            args.r_user,
        )

        sync_status = bdsync(
            local_device, args.r_host, args.r_vg, args.r_snapshot_name, args.r_user
        )

        sys.exit(sync_status)

    finally:
        fcntl.flock(lock_file, fcntl.LOCK_UN)


if __name__ == "__main__":
    main()
