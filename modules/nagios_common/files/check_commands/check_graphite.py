#!/usr/bin/env python
'''
check_graphite
~~~~~~~

Based on the original plugin from disquis:
    https://github.com/disqus/nagios-plugins

:copyright: (c) 2014 Wikimedia Foundation
:license: Apache License 2.0, see LICENSE for more details.

 Can be tested like:
 ./files/icinga/check_graphite --url http://graphite.wikimedia.org check_threshold
   <metric-name> --from 15min -C 1 -W 2 --under
'''

import argparse
import json
import os
import re
import sys
import urllib2

from collections import defaultdict
from numbers import Real

try:
    # python 3.x compat
    from urlparse import urlparse
except ImportError:
    from urllib.parse import urlparse
try:
    from urllib.parse import urlencode
except ImportError:
    from urllib import urlencode


class NagiosException(Exception):
    NAGIOS_STATUSES = {
        'OK': 0,
        'WARNING': 1,
        'CRITICAL': 2,
        'UNKNOWN': 3
    }

    def __init__(self, exitcode, msg):
        self.exitcode = self.NAGIOS_STATUSES.get(exitcode, 3)
        self.msg = '%s: %s' % (exitcode, msg)

    def exit(self):
        sys.exit(self.exitcode)


class GraphiteCheck(object):
    '''
    Nothing to see here
    '''
    parser_name = 'check_generic'

    def __init__(self, args):
        '''
        :param args: Namespace with command-line arguments
        :returns: None
        '''
        self.targets = args.metric.split('::')  # expressions use commas!
        parsed_url = urlparse(args.url)
        if parsed_url.netloc.find('@') > 0:
            (self.credentials, host) = parsed_url.netloc.split('@')
        else:
            host = parsed_url.netloc
            self.credentials = None
        self.base_url = '%s://%s' % (parsed_url.scheme, host)
        # subclasses should just implement get_all here.
        self.get_all(args)

        # Dumb urllib2 basic auth support.
        if self.credentials:
            self._create_auth()

        self.http_timeout = args.timeout

    def _create_auth(self):
        user, password = self.credentials.split(':', 1)
        pwd_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
        pwd_manager.add_password(None, self.base_url, user, password)
        handler = urllib2.HTTPBasicAuthHandler(pwd_manager)
        opener = urllib2.build_opener(handler)
        urllib2.install_opener(opener)

    def get_all(self, args):
        # This should be implemented in subclasses
        raise NotImplementedError('Please implement this method in a subclass')

    def fetch(self):
        '''
        Fetches the required datapoints from the

        :returns: Parsed json structure (usually a list)
        :raises: NagiosException on non-OK statuses
        '''

        h = {'User-Agent': 'check_graphite/1.0'}

        full_url = '%s/render?%s' % (self.base_url, urlencode(self.params))

        try:
            req = urllib2.Request(full_url, None, h)
            response = urllib2.urlopen(req, None, self.http_timeout)
        except urllib2.HTTPError as e:
            raise NagiosException(
                'UNKNOWN', 'Got status %d from the graphite server at %s' %
                (e.code, full_url))
        except urllib2.URLError as e:
            raise NagiosException(
                'UNKNOWN', 'Could not reach the graphite server at %s, reason: %s' %
                (full_url, e.reason[1]))

        return json.load(response)

    @classmethod
    def create_parser(cls, parser):
        '''
        :param parser: the parser to attach the subparser to.
        :returns: argparse.ArgumentParser
        '''
        p = parser.add_parser(cls.parser_name, help=cls.__doc__)
        p.add_argument(
            'metric',
            metavar='METRIC',
            help='the metric to fetch from graphite')
        p.add_argument('-C', '--critical', dest='crit', type=float,
                       help='Threshold for critical alert (integer)')
        p.add_argument('-W', '--warning', dest='warn', type=float,
                       help='Threshold for warning (integer)')
        p.set_defaults(check_class=cls)
        return p

    def parse_result(self, result):
        raise NotImplementedError('Please implement this method in a subclass')

    def check_data(self, datapoints):
        raise NotImplementedError('Please implement this method in a subclass')

    def run(self):
        '''
        Runs all the processing pipeline. If successful it exits.

        :returns: None
        '''
        res = self.fetch()
        dp = self.parse_result(res)
        msg = self.check_data(dp)
        print('OK: %s' % msg)
        sys.exit(NagiosException.NAGIOS_STATUSES['OK'])


class Threshold(GraphiteCheck):

    '''
    Checks if the metric exceeds the desired threshold
    '''
    parser_name = 'check_threshold'
    timespec_regex = re.compile(r'^-(\d+)(\w+)$')
    _accepted_time_defs = ['hours', 'hour', 'h',
                           'weeks', 'week', 'w',
                           'days', 'day', 'd',
                           'minutes', 'minute', 'min']

    @classmethod
    def create_parser(cls, parser):
        p = super(Threshold, cls).create_parser(parser)
        p.add_argument(
            '--from',
            dest='_from',
            help='When to fetch the metric from (date or "-1d") (sign does not matter)',
            default='-1h')
        p.add_argument(
            '--until',
            dest='_until',
            help='When to fetch the metric until (date or "-1d") (sign does not matter)',
            default='-0min')
        p.add_argument(
            '--over',
            dest='over',
            action='store_true',
            default=True,
            help='If alarms should happen when we exceed the threshold')
        p.add_argument(
            '--under',
            dest='under',
            action='store_true',
            default=False,
            help='If alarms should happen when we are below the threshold')
        p.add_argument(
            '--perc',
            dest='percentage',
            default=1,
            type=int,
            help='Number of datapoints above or below threshold that will raise the alarm')
        return p

    def check_time_parameter(self, param_name, param_value):
        m = self.timespec_regex.match(param_value)
        if not m:
            raise ValueError(
                'the value of the %s argument is invalid: %s' %
                (param_name, param_value))
        if m.group(2) not in self._accepted_time_defs:
            raise ValueError('The unit specification for %s' % param_name
                             + 'should be one of the following: %s' %
                             ','.join(self._accepted_time_defs))

    def get_all(self, args):
        '''
        Gets additional data from the command-line args.

        :param args: Namespace with command-line arguments
        :returns: None
        '''
        _from = args._from
        if not args._from.startswith('-'):
            _from = '-%s' % args._from
        self.check_time_parameter('--from', _from)

        _until = args._until
        if not args._until.startswith('-'):
            _until = '-%s' % args._until
        self.check_time_parameter('--until', _until)

        self.params = [('format', 'json'), ('from', _from), ('until', _until)]
        for target in self.targets:
            self.params.append(('target', target))
        if args.under:
            self.under = True
            self.check_func = lambda x, y: x < y
        else:
            self.under = False
            self.check_func = lambda x, y: x > y
        self.limits = {}
        self.limits['WARNING'] = args.warn
        self.limits['CRITICAL'] = args.crit
        self.perc = args.percentage

    def parse_result(self, result):
        '''
        Parses the results of the fetch operation

        :param result: A data structure (tipically, a list)
                       with graphite datapoints
        :returns: a categorized list of datapoints
        '''
        datapoints = defaultdict(list)
        datapoints['_total'] = 0
        if len(result) == 0:
            return datapoints
        for (data, time) in result[0]['datapoints']:
            if not isinstance(data, Real):
                datapoints['UNKNOWN'].append((time, data))
                continue
            elif self.check_func(data, self.limits['CRITICAL']):
                datapoints['CRITICAL'].append((time, data))

            elif self.check_func(data, self.limits['WARNING']):
                datapoints['WARNING'].append((time, data))
            else:
                datapoints['OK'].append((time, data))
            datapoints['_total'] += 1
        return datapoints

    def check_data(self, datapoints):
        '''
        Checks the parsed datasets to emit the nagios status.

        :param datapoints: A dictionary of lists of categorized data.
        :returns: Message string containing the status.
        :raises: NagiosException on non-OK statuses
        '''
        if datapoints['_total'] == 0:
            raise NagiosException('UNKNOWN', 'No valid datapoints found')

        report = 'above'
        if self.under:
            report = 'under'

        lengths = {}
        t = datapoints['_total']
        for key in NagiosException.NAGIOS_STATUSES.keys():
            lengths[key] = len(datapoints[key])
        # Very simple count, no timeseries evaluation, no flap detection.
        if t < lengths['UNKNOWN']:
            raise NagiosException(
                'UNKNOWN', 'More than half of the datapoints are undefined')
        for key in ['CRITICAL', 'WARNING']:
            if lengths[key] >= t * self.perc / 100.0:
                perc = lengths[key] * 100.0 / t
                raise NagiosException(
                    key, '%3.2f%% of data %s the %s threshold [%s]' %
                    (perc, report, key.lower(), self.limits[key]))
        return 'Less than %3.2f%% %s the threshold [%s]' % \
            (self.perc, report, self.limits['WARNING'])


class SeriesThreshold(Threshold):

    '''
    Checks a series of metrics to see if they individually are within acceptable thresholds
    '''
    parser_name = 'check_series_threshold'
    allow_undefined = False

    def parse_result(self, result):
        '''
        Parses the results of the fetch operation

        :param result: A data structure (typically, a list)
                       with graphite datapoints
        :returns: A dictionary with key target and value categorized datapoints list
        '''
        seriespoints = {}
        for series in result:
            datapoints = defaultdict(list)
            datapoints['_total'] = 0
            for (data, time) in series['datapoints']:
                if not isinstance(data, Real):
                    datapoints['UNKNOWN'].append((time, data))
                    continue
                elif self.check_func(data, self.limits['CRITICAL']):
                    datapoints['CRITICAL'].append((time, data))

                elif self.check_func(data, self.limits['WARNING']):
                    datapoints['WARNING'].append((time, data))
                else:
                    datapoints['OK'].append((time, data))
                datapoints['_total'] += 1
            seriespoints[series['target']] = datapoints
        return seriespoints

    def check_data(self, seriespoints):
        '''
        Checks the parsed datasets to emit the nagios status.

        :param seriespoints: A dictionary of lists of categorized data.
        :returns: Message string containing the status.
        :raises: NagiosException on non-OK statuses
        '''
        messages = {'OK': [], 'CRITICAL': [], 'WARNING': []}
        if self.allow_undefined:
            messages['UNKNOWN'] = []

        for target, datapoints in seriespoints.iteritems():
            if datapoints['_total'] == 0:
                if self.allow_undefined:
                    messages['UNKNOWN'].append((target, 'No valid datapoints found'))
                    continue
                else:
                    raise NagiosException('UNKNOWN', 'No valid datapoints found for %s' % target)

            lengths = {}
            t = datapoints['_total']
            for key in NagiosException.NAGIOS_STATUSES.keys():
                lengths[key] = len(datapoints[key])
                # Very simple count, no timeseries evaluation, no flap detection.
            if t < lengths['UNKNOWN']:
                if self.allow_undefined:
                    messages['UNKNOWN'].append((
                        target, 'More than half of the datapoints are undefined'))
                    continue
                else:
                    raise NagiosException(
                        'UNKNOWN', 'More than half of the datapoints for %s are undefined' % target)
            for key in ['CRITICAL', 'WARNING']:
                if lengths[key] >= t * self.perc / 100.0:
                    perc = lengths[key] * 100.0 / t
                    messages[key].append((target, perc))
                    break
            else:
                messages['OK'].append((target, 100.0))

        message = self.format_message(messages)
        if messages['CRITICAL']:
            raise NagiosException('CRITICAL', message)
        elif messages['WARNING']:
            raise NagiosException('WARNING', message)
        else:
            return message

    def format_message(self, messages):
        if not (messages['CRITICAL'] or messages['WARNING']
                or ('UNKNOWN' in messages and messages['UNKNOWN'])):
            return 'All targets OK'
        sign = '<' if self.under else '>'
        message = ''
        if 'UNKNOWN' in messages and messages['UNKNOWN']:
            message += ' '.join(['%s (%s)' % (k, v) for k, v in messages['UNKNOWN']])
        if messages['CRITICAL']:
            message += ' '.join(['%s (%s%3.2f%%)' % (k, sign, v) for k, v in messages['CRITICAL']])
        if messages['WARNING']:
            if messages['CRITICAL']:
                message += ' WARN: '  # only add WARN: if there are also CRIT messages
            message += ' '.join(['%s (%s%3.2f%%)' % (k, sign, v) for k, v in messages['WARNING']])
        return message

    @classmethod
    def create_parser(cls, parser):
        p = super(SeriesThreshold, cls).create_parser(parser)
        p.add_argument('-a', '--allow-undefined', dest='allow_undefined', action='store_true',
                       default=False, help='Whether to allow undefined datapoints')
        return p

    def get_all(self, args):
        super(SeriesThreshold, self).get_all(args)
        self.allow_undefined = args.allow_undefined


class Anomaly(GraphiteCheck):
    '''
    Checks if the metric is out of the forecasted bounds for a number of times
    in the last iterations
    '''
    parser_name = 'check_anomaly'

    @classmethod
    def create_parser(cls, parser):
        p = super(Anomaly, cls).create_parser(parser)
        p.add_argument(
            '--check_window',
            dest='check_window',
            type=int,
            help='''How many datapoints to consider in the anomaly detection
sampling (we will still require 1w of data)''',
            default=20)
        p.add_argument(
            '--over',
            dest='over',
            action='store_true',
            default=False,
            help='If alarms should happen when we are above normal values')
        p.add_argument(
            '--under',
            dest='under',
            action='store_true',
            default=False,
            help='If alarms should happen when we are below normal values')

        return p

    def get_all(self, args):
        '''
        Gets additional data from the command-line args.

        :param args: Namespace with command-line arguments
        :returns: None
        '''
        self.params = [('format', 'json')]
        for target in self.targets:
            self.params.append(('target', target))
            self.params.append(
                ('target', 'holtWintersConfidenceBands(%s, 5)' % target))
        self.check_window = args.check_window
        self.warn = args.warn
        self.crit = args.crit
        self.over = args.over
        self.under = args.under

    def parse_result(self, result):
        '''
        Parses the results of the fetch operation

        :param result: A data structure (tipically, a list)
                       with graphite datapoints
        :returns: a categorized list of datapoints
        '''
        datapoints = defaultdict(list)
        my_slice = self.check_window * -1
        measures = result[0]['datapoints'][my_slice:]
        lowerbound = result[1]['datapoints'][my_slice:]
        upperbound = result[2]['datapoints'][my_slice:]
        for i in xrange(self.check_window):
            data, time = measures[i]
            lower = lowerbound[i][0]
            upper = upperbound[i][0]
            if not isinstance(data, Real):
                datapoints['unknown'].append((time, data))
            elif data >= upper:
                datapoints['higher'].append((time, data))
            elif data <= lower:
                datapoints['lower'].append((time, data))
            else:
                datapoints['ok'].append((time, data))
        return datapoints

    def check_data(self, datapoints):
        '''
        Checks the parsed datasets to emit the nagios status.

        :param datapoints: A dictionary of lists of categorized data.
        :returns: Message string containing the status.
        :raises: NagiosException on non-OK statuses
        '''
        unknown_len = len(datapoints['unknown'])
        higher_len = len(datapoints['higher'])
        lower_len = len(datapoints['lower'])
        ok_len = len(datapoints['ok'])
        total_len = higher_len + lower_len + ok_len
        if not total_len:
            raise NagiosException('UNKNOWN', 'No valid datapoints found')

        if total_len < unknown_len:
            raise NagiosException(
                'UNKNOWN', 'More than half of the datapoints are undefined')

        if (higher_len >= self.crit) or (lower_len >= self.crit):
            if (higher_len >= self.crit) and (lower_len >= self.crit):
                raise NagiosException(
                    'UNKNOWN',
                    'Service is critically flapping: %s data below and %s above'
                    ' the confidence bounds' % (higher_len, lower_len))

            if self.over and higher_len < self.crit:
                return 'No anomaly detected'

            if self.under and lower_len < self.crit:
                return 'No anomaly detected'

            raise NagiosException(
                'CRITICAL', 'Anomaly detected: %s data above and %s below the confidence bounds' %
                (higher_len, lower_len))

        if (higher_len >= self.warn) or (lower_len >= self.warn):
            if (higher_len >= self.warn) and (lower_len >= self.warn):
                raise NagiosException(
                    'UNKNOWN',
                    'Service is flapping: %s data below and %s above the confidence bounds' % (
                        higher_len, lower_len))
            if self.over and higher_len < self.warn:
                return 'No anomaly detected'

            if self.under and lower_len < self.warn:
                return 'No anomaly detected'

            raise NagiosException(
                'WARNING', 'Anomaly detected: %s data above and %s below the confidence bounds' %
                (higher_len, lower_len))

        return 'No anomaly detected'


def main():
    '''
    Controller for the graphite fetching plugin.

    You can build a few different type of checks, both traditional nagios checks
    and anomaly detection ones.

    Examples:

    Check if a metric exceeds a certain value 10 times in the last 20 minutes
    with a 5 minutes lag:

    ./check_graphite --url http://some-graphite-host \
           check_threshold my.beloved.metric  --from -20minutes \
           --until -5minutes --threshold 100 --over -C 10 -W 5

    Check if a metric has exceeded its holt-winters confidence bands 5% of the
    times over the last 500 checks

    ./check_graphyte.py --url http://some-graphite-host  \
          check_anomaly my.beloved.metric --check_window 500 -C 5 -W 1

    '''
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(
        title='check_type',
        help='use with --help for additional help',
        dest='check_type')

    Threshold.create_parser(subparsers)

    SeriesThreshold.create_parser(subparsers)

    Anomaly.create_parser(subparsers)

    parser.add_argument('-U', '--url', dest='url',
                        default=os.environ.get(
                            'GRAPHITE_URL', 'http://localhost'),
                        help='Url of the graphite server'
                        )
    parser.add_argument(
        '-T',
        '--timeout',
        dest='timeout',
        default=10,
        type=int,
        help='Timeout on the graphite call (defaults to 10)')

    args = parser.parse_args()

    try:
        checker = args.check_class(args)
        checker.run()
    except NagiosException as e:
        print(e.msg)
        e.exit()
    except Exception as e:
        # A generic error occurred, return an unknown status.
        print(
            'UNKNOWN: execution of the check script exited with exception %s' %
            e)
        sys.exit(NagiosException.NAGIOS_STATUSES['UNKNOWN'])


if __name__ == '__main__':
    # TODO - fix the docs
    __doc__ = main.__doc__
    main()
