#!/usr/bin/env python3

#####################################################################
# THIS FILE IS MANAGED BY PUPPET
# puppet:///modules/udp2log/udpmirror.py
#####################################################################

# Simple python script to send stdin to another host line by line


import argparse
import logging
import socket
import sys


DESCRIPTION = '''Relay stdin via UDP to the specified host/port, line by line.
When destination host resolves to multiple addresses (v4 only), lines will be
relayed to each.'''


def main():
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument('host', help='Destination host')
    parser.add_argument('port', help='Destination port')
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    log = logging.getLogger(__name__)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    gai = socket.getaddrinfo(args.host, args.port, socket.AF_INET)

    while True:
        line = sys.stdin.readline()
        if line == '':
            break

        for addrinfo in gai:
            try:
                sock.sendto(line, addrinfo[4])
            except (socket.gaierror, socket.error):
                log.exception('Error sending to %e:', addrinfo[4])
                continue


if __name__ == '__main__':
    sys.exit(main())
