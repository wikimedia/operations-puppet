#! /usr/bin/python3
# -*- coding: utf-8 -*-

import os
import re
import subprocess
import sys

import apt_pkg


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
    hostname = os.uname().nodename
    kernel_version_uname = os.uname().version

    for i in kernel_version_uname.split():
        if re.search(r'^[0-9]+\.[0-9]+\.[0-9]+-', i):
            current_kernelpackage_version = i
            break
    else:
        unknown('Failed to detect running kernel version from {}'.format(kernel_version_uname))

    apt_pkg.init()

    expected_cpu_flags = set()
    available_cpu_flags = set()

    try:
        systemd_detect_virt = subprocess.check_output('/usr/bin/systemd-detect-virt; exit 0',
                                                      shell=True, universal_newlines=True).strip()
    except subprocess.CalledProcessError as error:
        unknown('Could not determine host virtualisation status: {}'.format(str(error.returncode)))

    virtual_host = False
    if systemd_detect_virt in ['qemu', 'kvm']:
        virtual_host = True

    # CPUs which were not fixed for SSBD (which was the first) are also not
    # fixed for L1TF/MDS
    blacklist_ssbd_l1tf = ['dbproxy1001', 'dbproxy1002', 'dbproxy1007', 'dbproxy1008',
                           'es2001', 'es2002', 'es2003', 'es2004']
    blacklist_mds = ['cp1008', 'helium', 'tungsten', 'dbproxy1003'] + blacklist_ssbd_l1tf

    if apt_pkg.version_compare(current_kernelpackage_version, '4.9.107-1') > 0:
        expected_cpu_flags.add('ssbd')
    else:
        ok('No CPU flags are expected with the {} kernel'.format(current_kernelpackage_version))

    if not virtual_host:
        if apt_pkg.version_compare(current_kernelpackage_version, '4.9.110-3+deb9u3') > 0:
            expected_cpu_flags.add('flush_l1d')

    if apt_pkg.version_compare(current_kernelpackage_version, '4.9.168-1+deb9u1') > 0:
        expected_cpu_flags.add('md_clear')

    if 'ssbd' in expected_cpu_flags and hostname in blacklist_ssbd_l1tf:
        expected_cpu_flags.remove('ssbd')

    for flag in ['flush_l1d', 'md_clear']:
        if flag in expected_cpu_flags and hostname in blacklist_mds:
            expected_cpu_flags.remove(flag)

    if not expected_cpu_flags:
        ok('Hardware is too old')

    # Reading the flags from lscpu is not supported in jessie
    try:
        with open('/proc/cpuinfo', 'r') as proc_file:
            for l in proc_file.readlines():
                if l.startswith("flags"):
                    available_cpu_flags.update(l.split(":")[1].split())
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
