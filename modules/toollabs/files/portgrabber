#!/usr/bin/python

import os
import sys

import portgrabber

# Check that we are passed the tool name and an executable
# to call.
if len(sys.argv) <= 2:
    sys.stderr.write('Usage: portgrabber TOOLNAME EXECUTABLE [ARGUMENTS...]\n')
    sys.stderr.write('\n')
    sys.stderr.write(
        'portgrabber requests a free port number for TOOLNAME and then\n')
    sys.stderr.write('calls EXECUTABLE [ARGUMENTS...] PORT.\n')
    sys.exit(1)

# Set tool name.
tool = sys.argv[1]

# Attempt to get a local unused port
port = portgrabber.get_open_port()

# Connect to the proxylistener instances on the web proxies and notify
# them where requests for the tool need to be routed to.
portgrabber.register(port)

# Execute the program with the optional arguments and the port number
# appended.  The sockets are passed on to the program so that they are
# closed when the program terminates.
os.execvp(sys.argv[2], sys.argv[2:] + [str(port)])
