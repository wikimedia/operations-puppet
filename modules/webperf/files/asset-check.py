# -*- coding: utf-8 -*-
"""
  Gather stats about static assets count / size via asset-check.js
  Use gmetric to forward them to Ganglia.

  Copyright (C) 2013, Ori Livneh <ori@wikimedia.org>
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
    ('commons', 'http://commons.wikimedia.org/wiki/Main_Page'),
    ('dewiki', 'http://de.wikipedia.org/wiki/Wikipedia:Hauptseite'),
    ('enwiki', 'http://en.wikipedia.org/wiki/Main_Page'),
    ('enwiki-mobile', 'http://en.m.wikipedia.org/wiki/Main_Page'),
    ('eswiki', 'http://es.wikipedia.org/wiki/Wikipedia:Portada'),
    ('frwiki', 'http://fr.wikipedia.org/wiki/Wikipédia:Accueil_principal'),
    ('jawiki', 'http://ja.wikipedia.org/wiki/メインページ'),
    ('ruwiki', 'http://ru.wikipedia.org/wiki/Заглавная_страница'),
    ('zhwiki', 'http://zh.wikipedia.org/wiki/Wikipedia:首页'),
)


ap = argparse.ArgumentParser(description='Asset check Graphite module')
ap.add_argument('--statsd-host', default='localhost',
                type=socket.gethostbyname)
ap.add_argument('--statsd-port', default=8125, type=int)
args = ap.parse_args()

addr = args.statsd_host, args.statsd_port
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def dispatch_stats(name, stats):
    """Send metrics to Ganglia by shelling out to gmetric."""
    for type, data in stats.items():
        for measure, value in data.items():
            stat = ('frontend.assets.%s.%s.%s:%s|ms' %
                    (type, measure, name, value))
            logging.info(stat)
            sock.sendto(stat.encode('utf-8'), addr)


def gather_stats():
    """Acquire static stats for each configured URL."""
    for name, url in urls:
        command = ['phantomjs', 'asset-check.js', url]
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
