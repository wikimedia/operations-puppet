#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# This script is a wrapper script around Beeline - which is a commandline
# interface to HiveServer2.
#
# Beeline on it's own requires the database connection string to be
# specified everytime we launch it, which is not very user friendly.
# This script tries to set some good defaults to make this easy,
# while retaining the same interface as beeline.
#
# Beeline is installed at /usr/bin/beeline, and this wrapper is
# at /usr/local/bin which takes PATH precedence, such that when you invoke
# beeline this wrapper is launched. If you want to use the beeline script
# directly, use the one at /usr/bin.
#
# USAGE: beeline --help

import configparser
import os
import sys


# Read default configuration
CFG_FILE = '/etc/beeline.ini'

config = configparser.ConfigParser()
config.read(CFG_FILE)

jdbc_uri = config['DEFAULT']['jdbc']
output_format = config['DEFAULT'].get('format', 'tsv2')
verbose = config['DEFAULT'].getboolean('verbose', True)

DEFAULT_OPTIONS = {'-n': os.environ['USER'],
                   '--outputformat': output_format,
                   '--verbose': verbose,
                   '-u': jdbc_uri}


# Let's parse out arguments to see if values are set for the default
# options we have, if not add them to the argument list
ARGS = sys.argv[1:]
for option in DEFAULT_OPTIONS.keys():

    # Assume it's a short option, set up boolean flags for checking if
    # option is present in the list, and one for whether it is a long
    # option.
    option_present = option in ARGS
    is_long_option = False

    # Check if this is a long (--optionName) or short (-o) option
    if '--' in option[:2]:
        # This is a long option which follow the syntax --optionName=Value
        # so we are looking through the list of args to see if the substring
        # --optionName is available anywhere in the list
        option_present = any([option in arg for arg in ARGS])
        is_long_option = True

    # If the option is not present, look up our DEFAULT_OPTIONS dict and add it
    if not option_present:
        # Beeline expects long options to follow the --longOption=Value
        # format, so we must treat them differently.
        if is_long_option:
            ARGS += ['{}={}'.format(option, DEFAULT_OPTIONS[option])]
        else:
            ARGS += [option, DEFAULT_OPTIONS[option]]

# Pass args to the beeline process and replace the current process with
# beeline by using the exec call
os.execv('/usr/bin/beeline', ['/usr/bin/beeline'] + ARGS)
