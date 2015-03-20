#!/usr/bin/env python
# -*- coding: utf-8 -*-

# check-fresh-files-in-dir.py - nagios check for age of files in dir
#
# Copyright 2015 Brandon Black
# Copyright 2015 Wikimedia Foundation, Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import os
import glob
import time
import sys

def dir_exists(path):
    """Helper for argparse to check if a directory argument exists"""
    if not os.path.isdir(path):
        raise argparse.ArgumentTypeError("directory %s does not exist" % path)
    return path


def parse_options():
    """Parse command-line options, return args hash"""
    parser = argparse.ArgumentParser(description="Nagios dir freshness checker")
    parser.add_argument('--dir', '-d', dest="dir",
                        type=dir_exists,
                        help="directory to check (must exist)",
                        required=True)
    parser.add_argument('--warn-age', '-w', dest="warn_age",
                        help="warn if file age in secs > this",
                        type=int,
                        default=3600)
    parser.add_argument('--crit-age', '-c', dest="crit_age",
                        help="crit if file age in secs > this",
                        type=int,
                        default=86400)
    parser.add_argument('--glob', '-g', dest="file_glob",
                        help="Only check filenames within dir matching glob",
                        default='*')

    return parser.parse_args()


def main():
    args = parse_options()
    crit_out = []
    warn_out = []
    crit_time = time.time() - args.crit_age
    warn_time = time.time() - args.warn_age
    for checkme in glob.glob(os.path.join(args.dir, args.file_glob)):
        checkme_time = os.path.getmtime(checkme);
        if checkme_time < crit_time:
            crit_out.append("CRITICAL: File %s is more than %s secs old!"
                            % (checkme, args.crit_age))
        elif checkme_time < warn_time:
            warn_out.append("WARNING: File %s is more than %s secs old!"
                            % (checkme, args.warn_age))

    if crit_out:
        print "\n".join(crit_out)
        print "\n".join(warn_out)
        return 2

    if warn_out:
        print "\n".join(warn_out)
        return 1

    print "OK\n"
    return 0

if __name__ == '__main__':
    sys.exit(main())

# vim: set ts=4 sw=4 et:
