#!/usr/bin/python3
#
# Copyright 2021 Valentin Gutierrez
# Copyright 2021 Wikimedia Foundation, Inc.
#
# healthcheck that verifies that a varnish UDS socket works as expected.
# It assumes that PROXY protocol is enabled and injects
# a fake TCP4 address as varnish doesn't support PROXY UNKNOWN requests.
# Usage: check_varnish_uds --socket /run/varnish-frontend.socket

import argparse
import socket
import sys

OK = 0
CRITICAL = 2
UNKNOWN = 3


REQUEST = "PROXY TCP4 127.0.0.12 127.0.0.1 12345 80\r\n" \
          "GET /varnish-fe HTTP/1.0\r\n" \
          "Host: healthcheck.wikimedia.org\r\n" \
          "Connection: close\r\n" \
          "User-Agent: check_varnish_uds/0.1\r\n" \
          "\r\n"


def critical_exit(msg):
    sys.stderr.write("CRITICAL: {}\n".format(msg))
    sys.exit(CRITICAL)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Check if varnish UDS is able to handle HTTP requests"
    )
    parser.add_argument("--socket", help="Path to unix socket", required=True)
    parser.add_argument(
        "--timeout",
        default=60,
        type=int,
        help="Timeout for socket operations in seconds",
    )

    return parser.parse_args()


def main():
    args = parse_args()

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(args.timeout)

    try:
        sock.connect(args.socket)
    except socket.error as msg:
        critical_exit("cannot connect to {}: {}".format(args.socket, msg))

    try:
        sock.sendall(REQUEST.encode())
    except socket.error as msg:
        critical_exit("cannot write to {}: {}".format(args.socket, msg))

    data = sock.recv(1024)
    sock.close()
    if b"HTTP/1.1 200 OK" in data:
        print("OK: varnish UDS working as expected")
        sys.exit(OK)
    else:
        critical_exit("unexpected response: {}".format(data))


if __name__ == '__main__':
    main()
