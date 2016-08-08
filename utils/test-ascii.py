#!/usr/bin/env python
"""
test-ascii.py

Read filenames from stdin, and check each of them for non-ascii characters.

Returns the number of errors found (max 127).

"""
import sys
import subprocess

exitcode = 0

files = subprocess.check_output(["find", "-name", "*.pp", "-print0"]).split("\x00")
files = files[:-1]  # find returns a final empty element

for fn in files:
    try:
        for lineno, line in enumerate(open(fn), 1):
            line.decode('ascii')
    except UnicodeDecodeError as e:
        print("%s:%s: %s" % (fn, lineno, e))
        exitcode += 1

exitcode = min(exitcode, 127)
sys.exit(exitcode)
