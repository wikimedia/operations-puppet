#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  arclamp-grep -- analyze Arc Lamp logs. This is a CLI tool for parsing trace
  logs and printing a leaderboard of the functions which are most
  frequently on-CPU.

  usage: arclamp-grep [--resolution TIME] [--entrypoint NAME]
                      [--grep STRING] [--slice SLICE] [--count COUNT]
                      [--channel CHANNEL]

  Options:
   --resolution TIME   Which log files to analyze. May be one of 'hourly',
                       'daily', or 'weekly'. (Default: 'daily').

   --entrypoint NAME   Analyze logs for this entry point. May be one of
                       'all', 'index', 'api', or 'load'). (Default: 'all').

   --grep STRING       Only include stacks which include this string

   --count COUNT       Show the top COUNT entries. (Default: 20).

   --slice SLICE       Slice of files to analyze, in Python slice notation.
                       Files are ordered from oldest to newest, so
                       '--slice=-2:' means the two most recent files.
   --channel CHANNEL   Which channel to look at. defaults to "xenon"

  Copyright 2015 Ori Livneh <ori@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY CODE, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""
import argparse
import collections
import fnmatch
import glob
import operator
import os.path
import re
import sys
import textwrap


# Stack frames which match any of these shell-style wildcard patterns
# are excluded from the leaderboard.
SKIP_PATTERNS = ('*BagOStuff*', '*Http::exec*', '*ObjectCache*', '/srv*',
                 'AutoLoader*', 'Curl*', 'Database*', 'Hooks*', 'Http::*',
                 'LoadBalancer*', 'Memcached*', 'wfGetDB*')
RESET = '\033[0m'
YELLOW = '\033[93m'


def slicer(spec):
    args = re.match('(-?[0-9]+)?(?::(-?[0-9]+))?', spec).groups()
    args = [int(arg) if arg is not None else arg for arg in args]
    return lambda seq: operator.getitem(seq, slice(*args))


def should_skip(f):
    return f.lower() == f or any(fnmatch.fnmatch(f, p) for p in SKIP_PATTERNS)


def parse_line(line):
    line = re.sub(r'\d\.\d\dwmf\d+', 'X.XXwmfXX', line.rstrip())
    funcs, count = line.split(' ', 1)
    return funcs.split(';'), int(count)


def grep(fname, search_string):
    with open(fname) as f:
        for line in f:
            if search_string in line:
                yield line


def iter_funcs(files):
    for fname in files:
        for line in grep(fname, args.grep):
            funcs, count = parse_line(line)
            while funcs and should_skip(funcs[-1]):
                funcs.pop()
            if funcs:
                func = funcs.pop()
                for _ in range(count):
                    yield func


if {'-h', '--help'}.intersection(sys.argv):
    sys.exit(textwrap.dedent(__doc__))

arg_parser = argparse.ArgumentParser(add_help=False)
arg_parser.add_argument(
    '--resolution',
    default='daily',
    choices=('hourly', 'daily', 'weekly'),
)
arg_parser.add_argument(
    '--count',
    default=20,
    type=int,
    help='show this many entries',
)
arg_parser.add_argument(
    '--entrypoint',
    choices=('all', 'index', 'api', 'load'),
    default='all',
)
arg_parser.add_argument(
    '--grep',
    default='',
    help='only include stacks which include this string',
)
arg_parser.add_argument(
    '--slice',
    default='-2:',
    help='slice of files to consider',
    type=slicer,
)
arg_parser.add_argument(
    '--channel',
    default='xenon',
    help='What channel to look at',
    choices=['xenon', 'excimer'],
)
args = arg_parser.parse_args()

# Legacy: the 'xenon' channel has a generic filename for now.
if args.channel == 'xenon':
    glob_pattern = '/srv/xenon/logs/%(resolution)s/*.%(entrypoint)s.log'
else:
    glob_pattern = '/srv/xenon/logs/%(resolution)s/*.%(channel)s.%(entrypoint)s.log'
file_names = glob.glob(glob_pattern % vars(args))
file_names.sort(key=os.path.getctime)
file_names = args.slice(file_names)
counter = collections.Counter(iter_funcs(file_names))
total = sum(1 for _ in counter.elements())

max_len = max(len(f) for f, _ in counter.most_common(args.count))

desc = 'Top %d functions' % args.count
if args.grep:
    desc += ' in traces matching "%s"' % args.grep
if args.entrypoint == 'all':
    desc += ', all entry-points:'
else:
    desc += ', %s.php:' % args.entrypoint

print(desc)
print('-' * len(desc))

for idx, (func, count) in enumerate(counter.most_common(args.count)):
    ordinal = idx + 1
    percent = 100.0 * count / total
    func = YELLOW + (('%% -%ds' % max_len) % func) + RESET
    print('% 4d | %s |% 5.2f%%' % (ordinal, func, percent))

print('-' * len(desc))
print('Log files:')
for f in file_names:
    print(' - %s' % f)
print('')
