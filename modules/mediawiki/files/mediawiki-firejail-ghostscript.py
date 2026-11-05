#!/usr/bin/python3

import subprocess
import sys

subprocess.call([
    '/usr/bin/firejail',
    '--quiet',
    '--profile=/etc/firejail/mediawiki-converters.profile',
    '/usr/bin/gs'] + sys.argv[1:])
