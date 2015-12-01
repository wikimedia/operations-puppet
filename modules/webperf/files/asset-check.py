# -*- coding: utf-8 -*-
"""
  Gather stats about static assets count / size via asset-check.js
  and forward them to StatsD.

  Copyright (C) 2013, 2014, Ori Livneh <ori@wikimedia.org>
  Licensed under the terms of the GPL, version 2 or later.
"""
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import argparse
import json
import logging
import socket
import subprocess
import time


interval = 300  # 5 minutes.

urls = (
    ('commons', 'https://commons.wikimedia.org/?mainpage'),
    ('dewiki', 'https://de.wikipedia.org/?mainpage'),
    ('enwiki', 'https://en.wikipedia.org/?mainpage'),
    ('enwiki-mobile', 'https://en.m.wikipedia.org/?mainpage'),
    ('eswiki', 'https://es.wikipedia.org/?mainpage'),
    ('frwiki', 'https://fr.wikipedia.org/?mainpage'),
    ('jawiki', 'https://ja.wikipedia.org/?mainpage'),
    ('ruwiki', 'https://ru.wikipedia.org/?mainpage'),
    ('wikidatawiki', 'https://www.wikidata.org/?mainpage'),
    (
        'wikidatawiki-berlin-276539678',
        'https://www.wikidata.org/w/index.php?title=Q64&oldid=276539678'
    ),
    ('zhwiki', 'https://zh.wikipedia.org/?mainpage'),
)


ap = argparse.ArgumentParser(description='Asset check Graphite module')
ap.add_argument('--statsd-host', default='localhost',
                type=socket.gethostbyname)
ap.add_argument('--statsd-port', default=8125, type=int)
args = ap.parse_args()

addr = args.statsd_host, args.statsd_port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def dispatch_stats(name, stats):
    """Send metrics to StatsD."""
    for type, data in stats.items():
        for measure, value in data.items():
            stat = ('frontend.assets.%s.%s.%s:%s|ms' %
                    (type, measure, name, value))
            logging.info(stat)
            sock.sendto(stat.encode('utf-8'), addr)


def gather_stats():
    """Acquire static stats for each configured URL."""
    for name, url in urls:
        command = ['phantomjs', '--ssl-protocol=any', 'asset-check.js', url]
        try:
            stats = json.loads(subprocess.check_output(command))
        except (subprocess.CalledProcessError, ValueError):
            logging.exception('Failed to check %s', url)
        else:
            dispatch_stats(name, stats)


while 1:
    start = time.time()
    gather_stats()
    elapsed = time.time() - start
    time.sleep(interval - elapsed)
