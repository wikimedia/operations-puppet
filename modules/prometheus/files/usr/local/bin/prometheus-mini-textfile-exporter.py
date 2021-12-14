#!/usr/bin/python3
"""
Bare bones exporter for textfile-based metrics.

The main use case is to be able to export custom metrics without interfering
with node-exporter jobs and/or settings. For example being able to use
'honor_labels: true' in Prometheus.
"""

import argparse
import logging
import sys
import glob
import time

from prometheus_client.parser import text_fd_to_metric_families
from prometheus_client.core import REGISTRY
from prometheus_client import start_http_server


class MiniTextfileCollector(object):
    def __init__(self, globs):
        self.globs = globs

    def collect(self):
        for g in self.globs:
            for mf in self.glob_to_metric_families(g):
                yield mf

    def glob_to_metric_families(self, g):
        for path in glob.glob(g):
            with open(path) as f:
                for mf in text_fd_to_metric_families(f):
                    yield mf


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--glob",
        help="Glob to read metric files from",
        action="append",
    )
    parser.add_argument(
        "-l", "--listen", help="Listen on this address", default="127.0.0.1"
    )
    parser.add_argument(
        "-p", "--port", help="Listen on this port", default=9716, type=int
    )
    parser.add_argument(
        "-d", "--debug", action="store_true", help="Enable debug logging"
    )
    args = parser.parse_args()

    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    REGISTRY.register(MiniTextfileCollector(args.glob))

    start_http_server(args.port, args.listen)

    try:
        while True:
            time.sleep(1.0)
    except KeyboardInterrupt:
        return 1


if __name__ == "__main__":
    sys.exit(main())
