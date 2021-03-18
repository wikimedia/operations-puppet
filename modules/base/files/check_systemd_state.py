#! /usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  Copyright 2016 Alexandros Kosiaris <akosiaris@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED 'AS IS' AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
'''
check_systemd_state

usage: check_systemd_state

Checks that the systemd overall state is ok. The status codes and corresponding
states in the STATES variable are taken straight out of the systemctl manpage
'''

import subprocess
import sys


STATES = {
    'initializing': 'Early bootup, before basic.target is reached or the \
        maintenance state entered.',
    'starting': 'Late bootup, before the job queue becomes idle for the \
        first time, or one of the rescue targets are reached.',
    'running': 'The system is fully operational',
    'degraded': 'The system is operational but one or more units failed.',
    'maintenance': 'The rescue or emergency target is active.',
    'stopping': 'The manager is shutting down.',
    'offline': 'The manager is not running. Specifically, this is the \
        operational state if an incompatible program is running as \
        system manager (PID 1).',
    'unknown': 'The operational state could not be determined, due to \
        lack of resources or another error cause.'
}


def unknown(msg):
    print('UNKNOWN - %s' % msg)
    sys.exit(3)


def critical(msg):
    print('CRITICAL - %s' % msg)
    sys.exit(2)


def warning(msg):
    print('WARNING - %s' % msg)
    sys.exit(1)


def ok(msg):
    print('OK - %s' % msg)
    sys.exit(0)


def get_failed_units():
    try:
        failed = subprocess.check_output(
            ['/bin/systemctl', 'list-units', '--failed', '--plain', '--no-legend']
        )
        units = [f.split()[0] for f in failed.decode().strip().split('\n')]
        units.sort()
        STATES['degraded'] = 'The following units failed: {}'.format(','.join(units))
    except Exception:
        # if an exception is thrown, we just ignore the output
        STATES['degraded'] += ' An error occured trying to list the failed units'


def main():
    try:
        output = subprocess.check_output(
            ['/bin/systemctl', 'is-system-running'],
            stderr=subprocess.STDOUT).decode().strip()
        func = ok
    except subprocess.CalledProcessError as e:
        output = e.output.decode().strip()
        if output in ['initializing', 'starting', 'stopping']:
            func = warning
        if output == 'unknown':
            func = unknown
        else:
            func = critical
            if output == 'degraded':
                get_failed_units()
    except UnicodeError as e:
        output = e.message
        func = unknown
    func('{}: {}'.format(output, STATES.get(output, 'unexpected')))


if __name__ == '__main__':
    main()
    unknown('Unexpected end of program reached')
