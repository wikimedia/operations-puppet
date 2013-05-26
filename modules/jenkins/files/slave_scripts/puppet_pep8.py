#!/usr/bin/python

import argparse
import os
import subprocess

parser = argparse.ArgumentParser(description=
                                 "Run the pep8 tool on each file in <path> and"
                                 " its subdirs.\n"
                                 "This differs from the normal pep8 tool in"
                                 " that pep8 is invoked per file rather than"
                                 " as one job; this means it can load a"
                                 " different .pep8 rule for each subdir.")
parser.add_argument('path', help='top level dir to begin pep8 tests')
args = parser.parse_args()

dir_tuples = os.walk(args.path)

success = True
for dir_tuple in dir_tuples:
    for f in dir_tuple[2]:
        if os.path.splitext(f)[1] == ".py":
            file_path = os.path.join(dir_tuple[0], f)
            print "Checking file %s" % file_path
            args = ('/usr/local/bin/pep8', file_path)
            if subprocess.call(args):
                success = False

if success:
    print "\n\nAll tests passed."
    exit(0)
else:
    exit(1)
