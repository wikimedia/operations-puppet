#!/usr/bin/env python
# This is a simple validator for external pybal node
# definition files.  These are loaded and eval'd
# line by line.  A faulty eval will cause issues.

import sys
file = open(sys.argv[1], 'r').read()
for l in file.splitlines():
    #this mimics internal pybal behavior
    l = l.rstrip('\n').strip()
    if l.startswith('#') or not l:
        continue

    try:
        server = eval(l)
        assert type(server) == dict
        assert all(map(lambda k: k in server, ['host', 'enabled', 'weight']))
    except Exception as e:
        print l, e
        sys.exit(1)
