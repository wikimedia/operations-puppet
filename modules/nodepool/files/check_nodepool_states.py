#!/usr/bin/env python
"""
General health check for nodepool state management
"""
import argparse
from collections import Counter
import logging
import sys
import subprocess

# described as 'Age (hours)' this resets upon state
# change. i.e. building => ready => used
#
# 'nodepool hold xxxx' is an administrative freeze
# for debugging.
#
thresholds = {
    'building': .10,
    'delete': .10,
    'used': 1.5,
    'hold': 24,
}


def main():
    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO)

    instances_raw = subprocess.check_output(['/usr/bin/nodepool', 'list'])
    aliens_raw = subprocess.check_output(['/usr/bin/nodepool', 'alien-list'],
                                         stderr=subprocess.STDOUT)

    logging.debug(instances_raw)
    logging.debug(aliens_raw)

    # nodepool puts instances here it thinks should not exist
    # this is a graceful indication of failed deletion
    aliens = []
    for line in aliens_raw.splitlines():
        if 'snapshot' in line:
            continue
        if 'wmflabs-eqiad' in line:
            aliens.append(line)

    if aliens:
        logging.warning(str(aliens))
        print '{} nodepool alien(s) present'.format(len(aliens))
        sys.exit(1)

    instances = {}
    for line in instances_raw.splitlines():
        if 'wmflabs-eqiad' in line:
            props = [x.strip() for x in line.split('|') if x]
            instances[props[5]] = {
                'label': props[3],
                'name': props[5],
                'UUID': props[7],
                'address': props[8],
                'state': props[9].lower(),
                'age': float(props[10]),
            }

    issues = []
    for name, values in instances.iteritems():
        logging.debug("{}: {}".format(name, str(values)))

        state_max = thresholds.get(values['state'], 0)

        if not state_max:
            continue

        if values['age'] >= state_max:
            issues.append(values)

    if len(issues) > 0:
        logging.debug(str(issues))
        bad_states = [x['state'] for x in issues]
        details = str(dict(Counter(bad_states)))
        print "{} instances in bad state ({})".format(len(issues), details)
        sys.exit(1)

    print 'nodepool state management is OK'

if __name__ == '__main__':
    main()
