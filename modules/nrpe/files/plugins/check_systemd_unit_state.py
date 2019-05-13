#! /usr/bin/python3
# -*- coding: utf-8 -*-
#
#  Copyright © 2015 Marc-André Pelletier <mpelletier@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
#  THIS FILE IS MANAGED BY PUPPET
#
#  Source: modules/nrpe/files/plugins/check_systemd_unit_state
#  From:   modules/nrpe/manifests/systemd_scripts.pp
#

"""
check_systemd_unit_state

usage: check_systemd_unit_state <unit> <expect> [<lastrun>]

Checks that the systemd unit <unit> is in the correct state according
to <expect>:

    active   - Ok if the unit is active and running
    inactive - Ok if the unit is inactive and dead
    periodic - Ok if the unit is either:
                 (a) active and running
                 (b) inactive, dead and the last result was success
               In addition, if <lastrun> is specified, the checks
               returns Ok iff the unit was started no more than
               <lastrun> seconds ago (and this information is only
               valid when a timer exists for the unit)
"""

import datetime
import subprocess
import sys
import time


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

    try:
        lastrun = None
        unit = sys.argv[1]
        expect = sys.argv[2]
        if expect not in ['active', 'inactive', 'periodic']:
            unknown("Must expect one of 'active', 'inactive', or 'periodic'")
        if expect == 'periodic' and len(sys.argv) > 3:
            lastrun = datetime.timedelta(seconds=int(sys.argv[3]))
    except (IndexError, ValueError):
        unknown("Bad arguments to %s (%s)"
                % (sys.argv[0], ", ".join(sys.argv[1:])))

    state = {}
    try:
        raw = subprocess.check_output(
            ['/bin/systemctl', 'show', unit], stderr=subprocess.STDOUT
        ).decode()
        for entry in raw.splitlines():
            kv = entry.split('=', 1)
            state[kv[0]] = kv[1]
    except IndexError:
        unknown("Unable to parse status of unit %s" % unit)

    if expect == 'active':

        if state['ActiveState'] != 'active':
            crit("Expecting active but unit %s is %s"
                 % (unit, state['ActiveState']))
        sstate_want = 'running'
        if state['Type'] == 'oneshot' and state['RemainAfterExit'] == 'yes':
            sstate_want = 'exited'
        if state['SubState'] != sstate_want:
            crit("Unit %s is active but reported SubState %s, wanted %s'"
                 % (unit, state['SubState'], sstate_want))
        ok("%s is active" % unit)

    elif expect == 'inactive':

        if state['ActiveState'] != 'inactive':
            crit("Expecting inactive but unit %s is %s"
                 % (unit, state['ActiveState']))
        if state['SubState'] != 'dead':
            crit("Unit %s is inactive but reported %s'"
                 % (unit, state['SubState']))
        ok("%s is inactive" % unit)

    # else periodic

    if state['Result'] != 'success':
        crit("Last run result for unit %s was %s" % (unit, state['Result']))

    if lastrun:
        try:
            # Timestamps in systemctl show are 'Thu 2015-07-30 16:56:59 UTC'
            started = datetime.datetime.strptime(
                state['ExecMainStartTimestamp'],
                '%a %Y-%m-%d %H:%M:%S %Z'
            )
            age = datetime.datetime.fromtimestamp(int(time.time())) - started

            if age > lastrun:
                crit("Last run for unit %s was over %s ago" % (unit, lastrun))

        except (KeyError, ValueError):
            unknown("Unit %s has no usable last run information (not a timer?)"
                    % unit)

    ok("Last run for unit %s was successful" % unit)


if __name__ == "__main__":
    main()
