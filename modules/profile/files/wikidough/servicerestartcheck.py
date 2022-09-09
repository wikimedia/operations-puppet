#! /usr/bin/env python3

"""servicerestartcheck.py: Really, you should restart that service!

This script checks to make sure that if a configuration file was changed, the
related systemd service was also restarted so that the service can pick up and
apply the new changes.

For a more practical example: some services such as dnsdist and pdns-recursor
don't support reloading of the configuration and so their systemd service has
to be restarted whenever a configuration file changes. But restarting also
means clearing out the cache, so ideally we would like to manage such restarts
ourselves versus letting Puppet do that and because of that, any change to a
configuration file should not result in an automatic restart.

The purpose of this script is to check if a configuration file change (mtime)
is more recent than the subsequent service restart (ActiveEnterTimestamp), to
remind us to restart the service (WARNING). If the time delta between the mtime
and ActiveEnterTimestamp exceeds 24 hours (configurable), then it raises the
alert from WARNING to CRITICAL.
"""

import argparse
import enum
import os
import sys

import pystemd


class StatusCode(enum.IntEnum):
    OK = 0
    WARNING = 1
    CRITICAL = 2


def write_msg(status_code, msg):
    print(msg)
    sys.exit(status_code.value)


def unit_active_time(service):
    unit = pystemd.systemd1.Unit(service.encode())
    unit.load()

    # Check if the service is active and if not, we should report that.
    if unit.Unit.ActiveState == b'active':
        # From https://www.freedesktop.org/wiki/Software/systemd/dbus/,
        # ActiveEnterTimestamp is in microseconds.
        active_time = unit.Unit.ActiveEnterTimestamp
        return active_time / 1000000
    else:
        write_msg(StatusCode.CRITICAL,
                  f"CRITICAL: Service {service} is not active.")


def file_last_modified(file_path):
    try:
        modified_time = os.path.getmtime(file_path)
    except FileNotFoundError:
        write_msg(StatusCode.CRITICAL,
                  f"CRITICAL: Configuration file {file_path} not found.")

    return modified_time


def parse_args():
    desc = ("Alerts if a configuration file change is more recent than that "
            "of a systemd unit restart.")
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument("-s", "--service",
                        required=True,
                        help="name of the service to monitor")
    parser.add_argument("-f", "--file",
                        required=True,
                        help="path to the configuration file")
    parser.add_argument("--critical",
                        type=int, default=24,
                        help="time (h) after which to raise alert to CRITICAL")
    return parser.parse_args()


def main():
    args = parse_args()

    unit_time = unit_active_time(args.service)
    file_time = file_last_modified(args.file)
    diff = file_time - unit_time

    if file_time > unit_time:
        alert = (StatusCode.CRITICAL if (diff > args.critical * 3600)
                 else StatusCode.WARNING)
        msg = (f"{alert.name}: Service {args.service} has not been restarted "
               f"after {args.file} was changed (stale by {diff:.2f}s).")
        write_msg(alert, msg)
    else:
        msg = (f"OK: {args.service} was restarted after {args.file} "
               f"was changed (within 3600 seconds).")
        write_msg(StatusCode.OK, msg)


if __name__ == "__main__":
    main()
