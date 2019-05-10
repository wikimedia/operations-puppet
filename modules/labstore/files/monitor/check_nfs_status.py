#!/usr/bin/python3
import argparse
import os
import subprocess
import sys


def check_nfs_status(cluster_ip):
    """
    Check if NFS is served over the cluster IP
    :param cluster_ip: string
    :returns: boolean
    """

    exports = [export for export in str(subprocess.check_output([
        '/sbin/showmount', '-e', cluster_ip])).split('\\n') if len(export) > 1]

    if len(exports) > 1:
        print('NFS served over cluster ip OK')
        return True

    print('No NFS exports served over Cluster IP')
    return False


def main():

    if not os.geteuid() == 0:
        print('Script not run as root')
        sys.exit(1)

    parser = argparse.ArgumentParser('Check if NFS is served over cluster IP')
    parser.add_argument('ip', help='Cluster IP assigned to primary node')
    args = parser.parse_args()

    if not check_nfs_status(args.ip):
        sys.exit(1)


if __name__ == '__main__':
    main()
