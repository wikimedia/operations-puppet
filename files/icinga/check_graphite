#!/usr/bin/env python
"""
check_graphite.py
~~~~~~~

Based on the original plugin from disquis:
    https://github.com/disqus/nagios-plugins

:copyright: (c) 2014 Wikimedia Foundation
:license: Apache License 2.0, see LICENSE for more details.
"""

import os
import json
import urllib3
from numbers import Real
import argparse
import ssl
import sys
from collections import defaultdict

try:
    #python 3.x compat
    from urlparse import urlparse
except ImportError:
    from urllib.parse import urlparse


class NagiosException(Exception):
    NAGIOS_STATUSES = {
        'OK': 0,
        'WARNING': 1,
        'CRITICAL': 2,
        'UNKNOWN': 3
}

    def __init__(self, exitcode, msg):
        self.exitcode = self.NAGIOS_STATUSES.get(exitcode, 3)
        self.msg = "%s: %s" % (exitcode, msg)


    def exit(self):
        sys.exit(self.exitcode)

class GraphiteCheck(object):
    parser_name='check_generic'
    """
    Nothing to see here
    """
    def __init__(self, args):
        self.targets = args.metric.split(',')
        parsed_url = urlparse(args.url)
        if parsed_url.netloc.find('@') > 0:
            (self.credentials, host) = parsed_url.netloc.split('@')
        else:
            host = parsed_url.netloc
            self.credentials = None
        self.base_url= "%s://%s" % (parsed_url.scheme, host)
        #subclasses should just implement get_all here.
        self.get_all(args)

        #Set up the http connectionpool
        http_opts = {}
        if args.timeout:
            http_opts['timeout'] = args.timeout
        if parsed_url.scheme == 'https':
            http_opts['ssl_version'] = ssl.PROTOCOL_TLSv1
            if args.ssl_certs:
                # We expect a combined cert
                http_opts['cert_file'] = args.ssl_certs
            #TODO: verify SSL by default

        self.http = urllib3.PoolManager(num_pools=10, **http_opts)


    def get_all(self,args):
        #This should be implemented in subclasses
        raise NotImplementedError

    def fetch(self):
        h = {'user_agent': 'check_graphite/1.0'}

        if self.credentials:
            h['basic_auth'] = self.credentials

        full_url = "%s/render" % self.base_url
        try:
            response = self.http.request(
                'GET',
                full_url,
                fields=self.params,
                redirect=True,
                headers=urllib3.util.make_headers(**h)
            )
        except urllib3.exceptions.MaxRetryError:
            raise NagiosException('UNKNOWN', 'Could not reach the graphite server at %s' % full_url)

        if response.status != 200:
            raise NagiosException('UNKNOWN', 'Got status %d from the graphite server at %s' % (response.status, full_url))

        return json.loads(response.data)

    @classmethod
    def create_parser(cls, parser):
        p = parser.add_parser(cls.parser_name, help=cls.__doc__)
        p.add_argument('metric', metavar='METRIC', help='the metric to fetch from graphite')
        p.add_argument('-C', '--critical', dest='crit', type=int, help='Threshold for critical alert (integer)')
        p.add_argument('-W', '--warning', dest='warn', type=int, help='Threshold for warning (integer)')
        p.set_defaults(check_class=cls)
        return p

    def parse_result(self, result):
        raise NotImplementedError

    def check_data(self, datapoints):
        raise NotImplementedError

    def run(self):
        res = self.fetch()
        dp = self.parse_result(res)
        self.check_data(dp)

class Threshold(GraphiteCheck):
    """
    Checks if the metric exceeds the desired threshold
    """
    parser_name='check_threshold'

    @classmethod
    def create_parser(cls,parser):
        p = super(Threshold,cls).create_parser(parser)
        p.add_argument('--from', dest='_from', help='When to fetch the metric from (date or "-1d")', default='-1h')
        p.add_argument('--over', dest="over", action='store_true', default=True, help='If alarms should happen when we exceed the threshold')
        p.add_argument('--under', dest="under", action='store_true', default=False, help='If alarms should happen when we are below the threshold')
        p.add_argument('--perc', dest="percentage", default=1, help='Number of datapoints above threshold that will raise the alarm')
        return p

    def get_all(self,args):
        self.params = [('format', 'json'), ('from', args._from)]
        for target in self.targets:
            self.params.append(('target', target))
        if args.under:
            self.check_func = lambda x, y: x < y
        else:
            self.check_func = lambda x, y: x > y
        self.limits ={}
        self.limits['WARNING'] = args.warn
        self.limits['CRITICAL'] = args.crit
        self.perc = args.percentage


    def parse_result(self, result):
        #TODO: make this work for lists of results
        datapoints = defaultdict(list)
        datapoints['_total'] = 0
        for (data,time) in result[0]['datapoints']:
            if not isinstance(data, Real):
                datapoints['UNKOWN'].append((time, data))
                continue
            elif self.check_func(data, self.limits['CRITICAL']):
                datapoints['CRITICAL'].append((time, data))

            elif self.check_func(data, self.limits['WARNING']):
                datapoints['WARNING'].append((time,data))
            else:
                datapoints['OK'].append((time,data))
            datapoints['_total'] += 1
        return datapoints

    def check_data(self,datapoints):
        #TODO: make this work for lists of results
        if not datapoints['_total']:
            raise NagiosException('UNKNOWN', 'No valid datapoints found')

        lengths = {}
        t = datapoints['_total']
        for key in NagiosException.NAGIOS_STATUSES.keys():
            lengths[key] = len(datapoints[key])
        #Very simple count, no timeseries evaluation, no flap detection.
        if t < lengths['UNKNOWN']:
            raise NagiosException('UNKNOWN', 'More than half of the datapoints are undefined')
        for key in ['CRITICAL', 'WARNING']:
            if lengths[key] >= t*self.perc/100.0:
                perc = lengths[key]*100.0/t
                raise NagiosException(key,
                                      '%s%% of data exceeded the %s threshold [%s]' %
                                      (perc, key.lower(), self.limits[key]))
        raise NagiosException('OK', 'Less than %s%% data above the threshold [%s]' % (self.perc, self.limits['WARNING']))

class Anomaly(GraphiteCheck):
    """
    Checks if the metric is out of the forecasted bounds for a number of times in the last iterations
    """
    parser_name='check_anomaly'

    @classmethod
    def create_parser(cls,parser):
        p = super(Anomaly,cls).create_parser(parser)
        p.add_argument('--check_window', dest="check_window", type=int, help='How many datapoints to consider in the anomaly detection sampling', default=20)
        return p

    def get_all(self,args):
        self.params = [('format', 'json')]
        for target in self.targets:
            self.params.append(('target', target))
            self.params.append(('target', 'holtWintersConfidenceBands(%s)' % target))
        self.check_window = args.check_window
        self.warn = args.warn
        self.crit = args.crit


    def parse_result(self, result):
        #TODO: make this work for lists of results
        datapoints = defaultdict(list)
        my_slice = self.check_window * -1
        measures = result[0]['datapoints'][my_slice:]
        lowerbound = result[1]['datapoints'][my_slice:]
        upperbound = result[2]['datapoints'][my_slice:]
        for i in xrange(self.check_window):
            data, time = measures[i]
            l = lowerbound[i][0]
            u = upperbound[i][0]
            if not isinstance(data, Real):
                datapoints['unknown'].append((time, data))
            elif data >= u:
                datapoints['higher'].append((time,data))
            elif data <= l:
                datapoints['lower'].append((time,data))
            else:
                datapoints['ok'].append((time,data))
        return datapoints

    def check_data(self, datapoints):
        u = len(datapoints['unknown'])
        h = len(datapoints['higher'])
        l = len(datapoints['lower'])
        ok = len(datapoints['ok'])
        t = h + l + ok
        if not t:
            raise NagiosException('UNKNOWN', 'No valid datapoints found')

        if t < u:
            raise NagiosException('UNKNOWN', 'More than half of the datapoints are undefined')

        #Simple check, with basic flap detection
        crit = (h >= self.crit) or (l >= self.crit)
        crit_flap = (h >= self.crit) and (l >= self.crit)
        if (h >= self.crit) or (l >= self.crit):
            if (h >= self.crit) and (l >= self.crit):
                raise NagiosException('UNKNOWN', 'Service is critically flapping below and above the confidence bounds')
            raise NagiosException('CRITICAL', 'Anomaly detected: %s data above and %s below the confidence bounds' % (h, l))

        if (h >= self.warn) or (l >= self.warn):
            if (h >= self.warn) and (l >= self.warn):
                raise NagiosException('UNKNOWN', 'Service is flapping below and above the confidence bounds')
            raise NagiosException('WARNING', 'Anomaly detected: %s data above and %s below the confidence bounds' % (h, l))

        raise NagiosException('OK', 'No anomaly detected')


def main():
    """
    Controller for the graphite fetching plugin.

    You can build a few different type of checks, both traditional nagios checks
    and anomaly detection ones.

    Examples:

    Check if a metric exceeds a certain value 10 times in the last 20 minutes:

    ./check_graphyte.py --url http://some-graphite-host \
           check_threshold my.beloved.metric  --from -20m \
           --threshold 100 --over -C 10 -W 5

    Check if a metric has exceeded its holter-winters confidence bands 5% of the
    times over the last 500 checks

    ./check_graphyte.py --url http://some-graphite-host  \
          check_anomaly my.beloved.metric --check_window 500 -C 5 -W 1

    """
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(
        title='check_type',
        help='use with --help for additional help',
        dest='check_type')

    threshold = Threshold.create_parser(subparsers)

    anomaly = Anomaly.create_parser(subparsers)


    parser.add_argument('-U', '--url', dest='url',
                        default=os.environ.get('GRAPHITE_URL', 'http://localhost'),
                        help='Url of the graphite server'
                        )
    parser.add_argument('-T', '--timeout', dest='timeout', default=10, help='Timeout on the graphite call (defaults to 10)')
    parser.add_argument('-S', '--client-ssl-cert', dest='ssl_certs', default=None, help='SSL client certificate to use in connection (filename)')


    args = parser.parse_args()

    try:
        checker = args.check_class(args)
        checker.run()
    except NagiosException as e:
        print(e.msg)
        e.exit()


if __name__ == '__main__':
    #TODO - fix the docs
    __doc__ = main.__doc__
    main()
