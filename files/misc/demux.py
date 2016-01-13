#####################################################################
# THIS FILE IS MANAGED BY PUPPET
# puppet:///files/misc/demux.py
#####################################################################

# Simple python script for demultiplexing MediaWiki log files

import argparse
import re
import string
import sys


transTable = string.maketrans("./", "__")
openFiles = {}
baseDir = '/a/mw-log'
nameRegex = re.compile(r"^[\040-\176]*$")

parser = argparse.ArgumentParser()
parser.add_argument('--basedir', help='destination path of log files')
args = parser.parse_args()
if args.basedir:
    baseDir = args.basedir

while True:
    # Use readline() not next() to avoid python's buffering
    line = sys.stdin.readline()
    if line == '':
        break

    try:
        (name, text) = line.split(" ", 1)
    except:
        # No name
        continue
    string.translate(name, transTable)

    # ASCII printable?
    if not nameRegex.match(name):
        continue

    name += '.log'
    try:
        if name in openFiles:
            f = openFiles[name]
        else:
            f = file(baseDir + '/' + name, "a")
            openFiles[name] = f
        f.write(text)
        f.flush()
    except:
        # Exit if it was a ctrl-C
        if sys.exc_info()[0] == 'KeyboardInterrupt':
            break

        # Close the file and delete it from the map,
        # in case there's something wrong with it
        if name in openFiles:
            try:
                openFiles[name].close()
            except:
                pass
            del openFiles[name]
