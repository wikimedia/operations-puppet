#!/usr/bin/env python3
# pylint: disable=too-many-branches
# pylint: disable=too-many-statements
# pylint: disable=too-many-locals
# vim:fenc=utf-8
"""Check if anycast-healthchecker and all configured threads are running.

Usage:
    check_anycast_healthchecker.py [-v]

Options:
    -v   report what it does
"""
import os
import sys
import configparser
import glob
import subprocess
from docopt import docopt


def get_processid(config):
    """Return process id of anycast-healthchecker.

    Arguments:
        config (obj): A configparser object with the configuration of
        anycast-healthchecker.

    Returns:
        The process id found in the pid file

    Raises:
        ValueError in the following cases
        - pidfile option is missing from the configuration
        - pid is either -1 or 1
        - stale pidfile, either with no data or invalid data
        - failure to read pidfile

    """
    pidfile = config.get('daemon', 'pidfile', fallback=None)
    if pidfile is None:
        raise ValueError("Configuration doesn't have pidfile option!")

    try:
        with open(pidfile, 'r') as _file:
            pid = _file.read().rstrip()
            try:
                pid = int(pid)
            except ValueError:
                raise ValueError("stale pid file with invalid data:{}"
                                 .format(pid))
            else:
                if pid in [-1, 1]:
                    raise ValueError("invalid PID ({})".format(pid))
                else:
                    return pid
    except OSError as exc:
        if exc.errno == 2:
            print("CRITICAL: anycast-healthchecker could be down as pid file "
                  "{} doesn't exist".format(pidfile))
            sys.exit(2)
        else:
            raise ValueError("error while reading pid file:{}".format(exc))


def running(pid):
    """Check the validity of a process ID.

    Note: We need root privilege for this.

    Arguments:
        pid (int): Process ID number.

    Returns:
        True if process ID is found otherwise False.

    """
    try:
        # From kill(2)
        # If sig is 0 (the null signal), error checking is performed but no
        # signal is actually sent. The null signal can be used to check the
        # validity of pid
        os.kill(pid, 0)
    except OSError:
        return False

    return True


def parse_services(config, services):
    """Parse configuration to return number of enabled service checks.

    Arguments:
        config (obj): A configparser object with the configuration of
        anycast-healthchecker.
        services (list): A list of section names which holds configuration
        for each service check

    Returns:
        A number (int) of enabled service checks.

    """
    enabled = 0
    for service in services:
        check_disabled = config.getboolean(service, 'check_disabled')
        if not check_disabled:
            enabled += 1

    return enabled


def main():
    """Run check.

    anycast-healthchecker is a multi-threaded software and for each
    service check it holds a thread. If a thread dies then the service
    is not monitored anymore and the route for the IP associated with service
    it wont be withdrawn in case service goes down in the meantime.
    """
    arguments = docopt(__doc__)
    config_file = '/etc/anycast-healthchecker.conf'
    config_dir = '/etc/anycast-healthchecker.d'
    config = configparser.ConfigParser()
    config_files = [config_file]
    config_files.extend(glob.glob(os.path.join(config_dir, '*.conf')))
    config.read(config_files)

    try:
        pid = get_processid(config)
    except ValueError as exc:
        print("UNKNOWN: {e}".format(e=exc))
        sys.exit(3)
    else:
        process_up = running(pid)

    if not process_up:
        print("CRITICAL: anycast-healthchecker with pid ({p}) isn't running"
              .format(p=pid))
        sys.exit(3)

    services = config.sections()
    services.remove('daemon')
    if not services:
        print("UNKNOWN: No service checks are configured")
        sys.exit(3)

    enabled_service_checks = parse_services(config, services)
    if enabled_service_checks == 0:
        print("OK: Number of service checks is zero, no threads are running")
        sys.exit(0)
    else:
        # parent process plus nummber of threads for each service check
        configured_threads = enabled_service_checks + 1

    cmd = ['/bin/ps', 'h', '-T', '-p', '{n}'.format(n=pid)]
    try:
        if arguments['-v']:
            print("running {}".format(' '.join(cmd)))
        out = subprocess.check_output(cmd, timeout=1)
    except subprocess.CalledProcessError as exc:
        print("UNKNOWN: running '{c}' failed with return code: {r}"
              .format(c=' '.join(cmd), r=exc.returncode))
        sys.exit(3)
    except subprocess.TimeoutExpired:
        print("UNKNOWN: running '{}' timed out".format(' '.join(cmd)))
        sys.exit(3)
    else:
        output_lines = out.splitlines()
        if arguments['-v']:
            for line in output_lines:
                print(line)
        running_threads = len(output_lines)
        if running_threads == configured_threads:
            print("OK: UP (pid={p}) and all threads ({t}) are running"
                  .format(p=pid, t=configured_threads - 1))
            sys.exit(0)
        elif running_threads - 1 == 0:  # minus parent process
            print("CRITICAL: No threads are running OpDocs ANYCAST-03")
            sys.exit(2)
        else:
            print("CRITICAL: Found {n} running threads while configured "
                  "number of threads is {c} OpDocs ANYCAST-03"
                  .format(n=running_threads - 1, c=configured_threads - 1))
            sys.exit(2)


# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
    main()
