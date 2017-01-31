#!/usr/bin/env python
import argparse
from collections import Counter
import logging
import sys
import subprocess

# described as 'Age (hours)' this resets upon state
# change. i.e. building => ready => used
thresholds = {
    'building': .10,
    'delete': .10,
    'active': .10,
    'used': .4,
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

    instances = {}
    for line in instances_raw.splitlines():
        if 'wmflabs-eqiad' in line:
            props = [x.strip() for x in line.split('|') if x]
            instances[props[5]] = {
                'type': props[3],
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
        print "{} violating max state age ({})".format(len(issues), details)
        sys.exit(1)

if __name__ == '__main__':
    main()
