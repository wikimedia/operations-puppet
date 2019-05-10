#!/usr/bin/python3
import argparse
import subprocess
import sys


def check_cluster_ip(node, role, interface, ip):
    """
    If role is primary, check that cluster IP is assigned to the interface,
    else make sure it is not.
    :param node: string
    :param role: string
    :param ip: string
    :returns: boolean
    """
    # Check if the ip is present in the list of IPv4 IPs assigned to interface
    ip_assigned = ip in str(subprocess.check_output(['/bin/ip', '-4', 'a', 'list', interface]))
    if (role == 'primary' and ip_assigned) or \
       (role == 'secondary' and not ip_assigned):
        print('Cluster IP assignment OK')
        return True

    print('{}: Unexpected cluster ip assignment for role {}'.format(
        node, role))
    return False


def main():

    parser = argparse.ArgumentParser('Check if cluster ip is assigned \
                                     to DRBD primary')
    parser.add_argument('node', help='Hostname of node being checked')
    parser.add_argument('role', help='Expected drbd role, primary|secondary')
    parser.add_argument('interface', help='Interface with an IP assigned')
    parser.add_argument('ip', help='Cluster IP assigned to primary node')
    args = parser.parse_args()

    if not check_cluster_ip(args.node, args.role, args.interface, args.ip):
        sys.exit(1)


if __name__ == '__main__':
    main()
