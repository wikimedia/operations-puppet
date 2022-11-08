#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
"""Check a JSON file and convert it to Icinga API.

The JSON file should have this structure:

  {
      "exit_code": 0,  # Integer following Icinga API: 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN
      "message": "some message"  # String with the message to print
      "timestamp": 1600881759"  # Integer or float with the seconds since epoch
      "performance": "perf data"  # [Optional] Icinga performance data string
  }

"""
import argparse
import json
import time

UNKNOWN = 3


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('file', help='Path to the JSON file to parse.')
    parser.add_argument('max_age', type=int, help=('How old the timestamp in the file can be, in '
                                                   'seconds, before considering the result stale'))
    args = parser.parse_args()

    try:
        with open(args.file) as f:
            try:
                data = json.load(f)
            except Exception as e:
                print('Failed to load data: {e}'.format(e=e))
                return UNKNOWN
    except Exception as e:
        print('Unable to read state file {name}: {e}'.format(name=args.file, e=e))
        return UNKNOWN

    if sum(1 for i in ('exit_code', 'timestamp', 'message') if i not in data):
        print('Invalid data: {data}'.format(data=data))
        return UNKNOWN

    delta = int(time.time() - data['timestamp'])
    if delta > args.max_age:
        print('Stale data from {delta} seconds ago, max age is {max_age}'.format(
            delta=delta, max_age=args.max_age))
        return UNKNOWN

    perf = data.get('performance', '')
    if perf:
        print('{msg} | {perf}'.format(msg=data['message'], perf=perf))
    else:
        print(data['message'])

    return data['exit_code']


if __name__ == '__main__':
    exit(main())
