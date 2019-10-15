"""
A logster parser that tails nginx log files to count responses grouped by first segment of urls

Examples:
    1. tools.wmflabs.org/geohack/geohack.php?x=50&y=50
        first segment: geohack
    2. tools.wmflabs.org/testtool
        firstsegment: testtool
    3. tools.wmflabs.org/
        firstsegment: /

It sends metrics of the form:
    raw.{firstsegment}.status.{status} -> For statuses!

It also sends combined metrics on a per status and per-http version basis.
"""
import re
from collections import defaultdict

from logster.logster_helper import MetricObject, LogsterParser
from logster.logster_helper import LogsterParsingException


class UrlFirstSegmentLogster(LogsterParser):

    def __init__(self, option_string=None):
        '''Initialize any data structures or variables needed for keeping track
        of the tasty bits we find in the log we are parsing.'''
        self.status_stats = {}

        self.combined_status = defaultdict(int)
        self.combined_httpver = defaultdict(int)
        # Regular expression for matching lines we are interested in, and capturing
        # fields from the line (in this case, http_status_code, size and squid_code).
        self.reg = re.compile(r"""
        ^(?P<vhost>[^ ]+)\s
        (?P<ip>(\d{1,3}\.?){4})\s
        (?P<ident>[^ ]+)\s
        (?P<userid>[^ ]+)\s
        \[(?P<timestamp>.*)\]\s
        "(?P<method>\w+)\s
        /(?P<firstsegment>[^/?]+)(?P<url>/.*?) HTTP/(?P<httpversion>\d.\d)"\s
        (?P<status>\d{3})\s
        (?P<len>\d+)\s
        "(?P<referer>.*?)"\s
        "(?P<useragent>.*?)"
        """, re.X)

    def parse_line(self, line):
        '''This function should digest the contents of one line at a time, updating
        object's state variables. Takes a single argument, the line to be parsed.'''

        # Apply regular expression to each line and extract interesting bits.
        regMatch = self.reg.match(line)

        if regMatch:
            bits = regMatch.groupdict()
            firstsegment = bits['firstsegment']
            status = bits['status']
            httpversion = bits['httpversion'].replace('.', '_')

            statuses = self.status_stats.get(firstsegment, {status: 0})
            statuses[status] = statuses.get(status, 0) + 1
            self.status_stats[firstsegment] = statuses
            self.combined_status[status] += 1

            self.combined_httpver[httpversion] += 1
        else:
            raise LogsterParsingException("regmatch failed to match")

    def get_state(self, duration):
        '''Run any necessary calculations on the data collected from the logs
        and return a list of metric objects.'''

        metrics = []
        for status, count in self.combined_status.items():
            metrics.append(
                MetricObject(
                    'combined.status.{status}'.format(status=status),
                    count,
                    'Responses'
                )
            )
        for httpver, count in self.combined_httpver.items():
            metrics.append(
                MetricObject(
                    'combined.httpver.{httpver}'.format(httpver=httpver),
                    count,
                    'Responses'
                )
            )
        for firstsegment, statuses in self.status_stats.items():
            for status, count in statuses.items():
                metric_name = 'raw.{firstsegment}.status.{status}'.format(
                    firstsegment=firstsegment, status=status
                )
                metrics.append(MetricObject(metric_name, count, 'Responses'))

        return metrics
