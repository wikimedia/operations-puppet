#!/usr/bin/env python3
"""Log lines to Prometheus counters for RPKI invalids.

This is a Prometheus exporter that is fed by Wikimedia-formatted JSON lines,
checks their RPKI status, and increments a counter depending on the validation
status.
"""

# Copyright © 2019 Wikimedia Foundation, Inc.
# Copyright © 2019 Faidon Liambotis <faidon@wikimedia.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY CODE, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import argparse
import fileinput
import logging
import logging.handlers
import pathlib
import re
import threading
import time

try:
    import ujson as json
except ImportError:
    import json

import urllib.request
import urllib.parse

import radix
import prometheus_client
from prometheus_client import Counter

# We use them throughout the code to catch all errors. We typically debug log,
# as well as increment an error counter while doing so, so at least they're not
# completely hidden.
#
# pylint: disable=broad-except

logger = logging.getLogger("rpkicounter")  # pylint: disable=invalid-name


class ANA:
    """Barebones interface for KPN (AS286)'s periodic RPKI dump."""

    def __init__(self, uri):
        url = urllib.parse.urlparse(uri)
        self.prefixes = None
        if url.scheme == "http" or url.scheme == "https":
            self.filename = None
            self.url = uri
        elif url.scheme == "":
            self.filename = uri
            self.url = None
        else:
            raise Exception("Unsupported URI with scheme " + url.scheme)

    def refresh(self):
        """Refresh the data from either a file or URL."""

        if self.filename:
            logger.debug("Refreshing ANA from file %s", self.filename)
            self.prefixes = self.read_and_parse_file(self.filename)
        else:
            logger.debug("Refreshing ANA from URL %s", self.url)
            self.prefixes = self.read_and_parse_url(self.url)
        logger.info("Refreshed ANA data: %d prefixes", len(self.prefixes.nodes()))

    def lookup(self, ipaddr):
        """Lookup an IP, return its validation status."""

        try:
            node = self.prefixes.search_best(ipaddr)
            altpfx = node.data["altpfx"]
            if altpfx:
                result = "invalid"
            else:
                result = "unreachable"
        except (AttributeError, KeyError):
            result = "valid-or-unverified"

        return result

    @classmethod
    def read_and_parse_file(cls, filename):
        """Read and parse an ANA file."""

        with open(filename, "r") as filehandle:
            return cls.parse(filehandle)

    @classmethod
    def read_and_parse_url(cls, url):
        """Read and parse an ANA URL."""

        response = urllib.request.urlopen(url)
        content = response.read().decode("utf-8")
        return cls.parse(content.splitlines())

    @staticmethod
    def parse(iterable):
        """Parse the ANA file format using a regexp, build a Patricia trie."""

        pattern = "^(?P<prefix>[^;]+);srcAS=(?P<asn>[^;]+);altpfx=(?P<altpfx>[^;]+);.*"

        prefixes = radix.Radix()
        for line in iterable:
            match = re.search(pattern, line)
            if match is None:
                continue

            prefix = match.group("prefix")
            if match.group("altpfx") == "NONE":
                altpfx = False
            else:
                altpfx = True

            node = prefixes.add(prefix)
            node.data["altpfx"] = altpfx

        if len(prefixes.nodes()) == 0:  # pylint: disable=len-as-condition
            raise Exception("Invalid ANA: prefix list is empty")

        return prefixes


class PeriodicRefresher:
    """Run a function periodically in a daemonized thread."""

    def __init__(self, func, interval, err_func, err_interval):
        self.func = func
        self.interval = interval
        self.err_func = err_func
        self.err_interval = err_interval

    def run(self):
        """Main entry point.

        Run func() once and spawn a background thread to run it in a loop."""

        # run once before we spawn the thread
        try:
            self.func()
        except Exception:
            self.err_func()

        # spawn the thread in the background
        thread = threading.Thread(target=self.loop, args=(), daemon=True)
        thread.start()

        # return the thread in case the caller wants to join etc.
        return thread

    def loop(self):
        """Run func() in a loop, sleeping for the set interval in between.

        If func() raises an exception, run err_func(), and switch to a separate
        interval. Useful if one wants to typically refresh e.g. every hour, but
        on transient failures not wait for another hour to catch up."""

        current_interval = self.interval
        while True:
            time.sleep(current_interval)
            try:
                self.func()
                current_interval = self.interval
            except Exception:
                self.err_func()
                current_interval = self.err_interval


class Processor:
    """Main logic for this program.

    1) Spawns a background thread for Prometheus
    2) Spawns a background thread to refresh the ANA data
    3) Processes JSON lines with IPs on the main thread
    """

    def __init__(self, args):
        self.args = args
        self.ana = ANA(args.uri)
        self.input = fileinput.input(args.input)

        self.counter = Counter("rpki_requests", "RPKI request status", ["status"])
        self.errors = Counter("rpki_errors", "RPKI parse errors", ["error"])

    def run(self):
        """Main function. Spawn background threads, and loop on input."""
        self.spawn_prometheus_thread()
        self.spawn_refresher_thread()

        # run this in the main thread
        while True:
            try:
                line = next(self.input)
                self.process_line(line)
            except UnicodeDecodeError as exc:
                logger.debug("Invalid input [%s]: %s", type(exc).__name__, exc)
            except StopIteration:
                break

    def spawn_prometheus_thread(self):
        """Start a background thread for Prometheus."""
        prometheus_client.start_http_server(self.args.port)

    def spawn_refresher_thread(self):
        """Start a background thread for refreshing the ANA data."""

        refresher = PeriodicRefresher(
            func=self.ana.refresh,
            interval=self.args.refresh,
            err_func=self.errors.labels("refresh-error").inc,
            err_interval=min(self.args.refresh, 60),
        )
        refresher.run()

    def process_line(self, line):
        """Process a JSON-formatted line and increment a Prometheus counter."""

        # parse the JSON and fetch the IP
        try:
            logline = json.loads(line)
            ipaddr = logline["ip"]
        except Exception as exc:
            logger.debug("Invalid input [%s]: %s", type(exc).__name__, exc)
            self.errors.labels("invalid-input").inc()
            return

        # do the actual lookup
        try:
            ana_result = self.ana.lookup(ipaddr)
        except Exception as exc:
            logger.debug("Lookup error [%s]: %s", type(exc).__name__, exc)
            self.errors.labels("lookup-error").inc()
            return

        # increment the Prometheus counter with the right status
        logger.debug("Lookup of %s -> %s", ipaddr, ana_result)
        self.counter.labels(ana_result).inc()


def parse_args(argv):
    """Parse and return the parsed command line arguments."""

    parser = argparse.ArgumentParser(prog="rpkicounter", description=__doc__)
    parser.add_argument(
        "--debug", action="store_true", help="Debug mode (log verbosely)"
    )
    parser.add_argument(
        "--port", type=int, default=9200, help="Prometheus port (default: %(default)s)"
    )
    parser.add_argument(
        "--refresh",
        type=int,
        default=60 * 60,
        help="Refresh interval for the ANA invalids data (default: 1h)",
    )
    parser.add_argument(
        "--uri",
        "--filename",
        default="https://as286.net/data/ana-invalids.txt",
        help="URL/filename of ana-invalids.txt (default: as286.net)",
    )
    parser.add_argument(
        "input",
        metavar="FILE",
        nargs="*",
        help="File(s) to read; if empty, stdin is used",
    )
    return parser.parse_args(argv)


def setup_logging(debug):
    """Setup logging format and level."""

    if debug:
        logger.setLevel(logging.DEBUG)
        stream_handler = logging.StreamHandler()
        fmt = logging.Formatter("%(asctime)s %(levelname)s: %(message)s")
        stream_handler.setFormatter(fmt)
        logger.addHandler(stream_handler)
    else:
        logger.setLevel(logging.INFO)
        # we cannot actually duck-type this, as Python >= 3.6 catches and
        # ignores all OSErrors in logging.handlers, including FileNotFoundError
        if pathlib.Path("/dev/log").is_socket():
            syslog_handler = logging.handlers.SysLogHandler(
                address="/dev/log", facility="daemon"
            )
        else:
            syslog_handler = logging.handlers.SysLogHandler(facility="daemon")
        fmt = logging.Formatter("%(name)s[%(process)d]: %(message)s")
        syslog_handler.setFormatter(fmt)
        logger.addHandler(syslog_handler)

    return logger


def main(argv=None):
    """Main entry point"""
    args = parse_args(argv)
    setup_logging(args.debug)

    processor = Processor(args)
    try:
        logger.info("rpkicounter starting up, reading from %s", args.uri)
        processor.run()
        if args.debug:
            logger.debug("Sleeping for 60s")
            # give some time to leave time to debug metrics over HTTP
            time.sleep(60)
    except (SystemExit, KeyboardInterrupt):
        pass


if __name__ == "__main__":
    main()
