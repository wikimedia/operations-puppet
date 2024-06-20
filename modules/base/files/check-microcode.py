#! /usr/bin/python3
# -*- coding: utf-8 -*-

import subprocess
import sys


def unknown(msg):
    print("UNKNOWN - %s" % msg)
    sys.exit(3)


def crit(msg):
    print("CRITICAL - %s" % msg)
    sys.exit(2)


def ok(msg):
    print("OK - %s" % msg)
    sys.exit(0)


def main():
    expected_cpu_flags = {'ssbd'}

    try:
        with open('/sys/devices/system/cpu/vulnerabilities/mds', 'r') as proc_file:
            if proc_file.readline() != 'Not affected\n':
                expected_cpu_flags.add('md_clear')

    except IOError:
        unknown('Failed to read MDS status from proc')

    available_cpu_flags = set()

    try:
        systemd_detect_virt = subprocess.check_output('/usr/bin/systemd-detect-virt; exit 0',
                                                      shell=True, universal_newlines=True).strip()
    except subprocess.CalledProcessError as error:
        unknown('Could not determine host virtualisation status: {}'.format(str(error.returncode)))

    virtual_host = False
    if systemd_detect_virt in ['qemu', 'kvm']:
        virtual_host = True

    if not virtual_host:
        try:
            with open('/sys/devices/system/cpu/vulnerabilities/l1tf', 'r') as proc_file:
                if proc_file.readline() != 'Not affected\n':
                    expected_cpu_flags.add('flush_l1d')

        except IOError:
            unknown('Failed to read L1TF status from proc')

    # Could be ported to lscp at some point
    try:
        with open('/proc/cpuinfo', 'r') as proc_file:
            for line in proc_file.readlines():
                if line.startswith("flags"):
                    available_cpu_flags.update(line.split(":")[1].split())
                    break
    except IOError:
        unknown('Failed to read CPU flags from proc')

    missing_cpu_flags = expected_cpu_flags - available_cpu_flags

    if missing_cpu_flags:
        crit('Server is missing the following CPU flags: {}'.format(missing_cpu_flags))
    else:
        ok('All expected CPU flags found')


if __name__ == "__main__":
    main()
