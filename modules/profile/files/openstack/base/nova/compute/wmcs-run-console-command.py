#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""
Runs a command on the console of a specific libvirt instance. This is intended
to be ran via a cookbook that runs it on a larger set of instances.

Note that this will execute whatever half-written commands there are on the
serial console, and it won't have the ability to get the output of the commands
executed.
"""
# loosely based on https://libvirt.gitlab.io/libvirt-appdev-guide-python/libvirt_application_development_guide_using_python-Events_and_Timers.html  # noqa: E501
import argparse
import time

import libvirt


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--connection", default="qemu:///system", help="libvirt socket address"
    )
    parser.add_argument("--instance", required=True, help="libvirt guest id")
    parser.add_argument("--command", required=True, help="command to execute")
    return parser.parse_args()


def main():
    args = parse_args()
    connection = libvirt.open(args.connection)
    guest = connection.lookupByName(args.instance)

    stream = connection.newStream(libvirt.VIR_STREAM_NONBLOCK)
    guest.openConsole(None, stream, 0)
    # timeouts required according to my tests. not sure why, if seeing
    # weird issues trying to raise them is a relatively safe bet
    time.sleep(0.2)
    stream.send(b"\n")
    time.sleep(0.2)
    stream.send(f"\n{args.command}\n".encode("utf-8"))
    time.sleep(0.2)


if __name__ == "__main__":
    main()
