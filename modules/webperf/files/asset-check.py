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

import json
import logging
import subprocess
import time


interval = 300  # 5 minutes.

defaults = {
    'type': 'uint32',
    'group': 'assets',
    'tmax': interval,
    'spoof': 'client-side:client-side',
}

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


def dispatch_stats(name, stats):
    """Send metrics to Ganglia by shelling out to gmetric."""
    for type, data in stats.items():
        for measure, value in data.items():
            metric = defaults.copy()
            metric.update({
                'name': 'assets_%s_%s_%s' % (type, measure, name),
                'value': value,
                'units': measure,
            })
            command = ['gmetric']
            args = sorted('--%s=%s' % (k, v) for k, v in metric.items())
            command.extend(args)
            subprocess.call(command)


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
