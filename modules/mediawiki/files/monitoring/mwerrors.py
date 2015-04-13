#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  mwerrors.py: MediaWiki errors StatsD reporter
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  This script listens on a UDP port for wfErrorLog()'d MediaWiki errors
  and fatals and reports them to StatsD.

  Command-line options:

    --listen-port  UDP port to listen on for log data (default: 8420).
    --statsd-host  StatsD server host (default: 'statsd').
    --statsd-port  StatsD server port (default: 8125).

  Copyright (C) 2014, Ori Livneh <ori@wikimedia.org>
  Licensed under the terms of the GNU General Public License, version 2
  or later.

"""
import sys
reload(sys)
sys.setdefaultencoding('utf8')

import argparse
import io
import socket


BLOCK_SIZE = 65536  # Udp2LogConfig::BLOCK_SIZE

patterns = (
    # Substring to match                # Metric
    ('Fatal error: Out of memory',      'oom'),
    ('Fatal error: Maximum execution',  'timelimit'),
    ('Fatal error:',                    'fatal'),
    ('Exception from',                  'exception'),
    ('Catchable fatal error',           'catchable'),
    ('DatabaseBase->reportQueryError',  'query'),
)

ap = argparse.ArgumentParser(description='MediaWiki errors StatsD reporter')
ap.add_argument('--listen-port', default=8420, type=int)
ap.add_argument('--statsd-host', default='statsd', type=socket.gethostbyname)
ap.add_argument('--statsd-port', default=8125, type=int)
args = ap.parse_args()

statsd_addr = args.statsd_host, args.statsd_port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('0.0.0.0', args.listen_port))

fd = sock.fileno()
with io.open(fd, buffering=BLOCK_SIZE, encoding='utf8', errors='replace') as f:
    for line in f:
        for pattern, metric_name in patterns:
            if pattern in line:
                stat = 'mw.errors.%s:1|c' % metric_name
                sock.sendto(stat.encode('utf-8'), statsd_addr)
                break
