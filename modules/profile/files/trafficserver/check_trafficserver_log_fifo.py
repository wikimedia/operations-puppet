#!/usr/bin/python3
#
# Copyright 2020 Emanuele Rocca
# Copyright 2020 Wikimedia Foundation, Inc.
#
# This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
# It may be used, redistributed and/or modified under the terms of the GNU
# General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
#
# Ensure that logs produced by SERVICE are being made available by
# fifo-log-demux on SOCKET.
#
# Usage: check_trafficserver_log_fifo --socket SOCKET --service SERVICE
#

import sys
import socket
import argparse
import subprocess

OK = 0
CRITICAL = 2


def critical_exit(msg):
    sys.stderr.write("CRITICAL: {}\n".format(msg))
    sys.exit(CRITICAL)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Check if fifo_log_demux is producing logs as expected"
    )
    parser.add_argument("--socket", help="Path to unix socket", required=True)
    parser.add_argument(
        "--service",
        help="Name of the service producing the logs (eg: ats-tls)",
        required=True,
    )
    parser.add_argument(
        "--timeout",
        default=60,
        type=int,
        help="Timeout for socket operations in seconds",
    )
    parser.add_argument(
        "--bytes",
        default=8,
        type=int,
        help="Amount of data to read from the socket in bytes",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    pooled = subprocess.run(["ispooled", args.service])
    if pooled.returncode == 1:
        print("OK: service {} is not pooled".format(args.service))
        sys.exit(OK)

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(args.timeout)

    try:
        sock.connect(args.socket)
    except socket.error as msg:
        critical_exit("cannot connect to {}: {}".format(args.socket, msg))
        sys.exit(CRITICAL)

    try:
        sock.sendall(" ".encode())
    except socket.error as msg:
        critical_exit("cannot write to {}: {}".format(args.socket, msg))

    try:
        data = sock.recv(args.bytes)
        datalen = len(data)
        if datalen < args.bytes:
            critical_exit("read {} bytes from {}".format(datalen, args.socket))
        else:
            print("OK: read {} bytes as expected".format(datalen))
            sys.exit(OK)
    except IOError as msg:
        critical_exit(
            "cannot read from {}: {}. Timeout is {} seconds.".format(
                args.socket, msg, args.timeout
            )
        )


if __name__ == "__main__":
    main()
