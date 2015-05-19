#!/usr/bin/python
import urllib2
import re
import sys
import argparse

status_line = re.compile('^mcg:\s+(\d+) bytes \((\d+)\%\) in (.*)$')

nagios_exits = {
    'OK': 0,
    'WARNING': 1,
    'CRITICAL': 2,
    'UNKNOWN': 3
}


def nagios_exit(state, msg):
    if not state in nagios_exits:
        state = 'UNKNOWN'
    print("HHVM_TC_SPACE {} {}".format(state, msg))
    sys.exit(nagios_exits[state])


def format_data(l):
    return "; ".join(["{}: {}%".format(el[0], el[1]) for el in l])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--warning', '-w', dest='warn',
                        help="Warning threshold", type=int)
    parser.add_argument('--critical', '-c', dest='crit',
                        help="Warning thresholds", type=int)
    args = parser.parse_args()
    try:
        response = urllib2.urlopen('http://localhost:9002/vm-tcspace')
        lines = response.readlines()
        WARNINGS = []
        CRITICALS = []
        for line in lines:
            m = status_line.match(line.rstrip())
            perc = int(m.group(2))
            if perc > args.crit:
                CRITICALS.append((m.group(3), perc))
            elif perc > args.warn:
                WARNINGS.append((m.group(3), perc))

        if CRITICALS:
            nagios_exit('CRITICAL', format_data(CRITICALS))
        if WARNINGS:
            nagios_exit('WARNING', format_data(WARNINGS))
        nagios_exit('OK', 'TC sizes are OK')
    except Exception as e:
        nagios_exit('UNKNOWN', "Unhandled error: {}".format(e))

if __name__ == '__main__':
    main()
