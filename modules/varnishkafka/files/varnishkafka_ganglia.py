#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Gmond module for posting metrics from varnishkafka.

    :copyright: (c) 2013 Wikimedia Foundation
    :author: Andrew Otto <otto@wikimedia.org>
    :license: GPLv2+
"""
# for true division when calculating rates of change
from __future__ import division

import copy
import json
import logging
import optparse
import os
import sys
import time
import difflib

logger = logging.getLogger('varnishkafka')


# metric keys to skip reporting to ganglia
skip_metrics = [
    'app_offset',
    'commited_offset',
    'desired',
    'eof_offset',
    'fetch_state',
    'fetchq_cnt',
    'fetchq_cnt',
    'leader',
    'lp_curr'
    'name',
    'next_offset',
    'nodeid',
    'partition',
    'query_offset',
    'seq',
    'state',
    'time',
    'topic',
    'toppars',
    'ts',
    'unknown',
]


def flatten_object(node, separator='.', key_filter_callback=None, parent_keys=None):
    '''
    Recurses through dicts and/or lists and flattens them
    into a single level dict of key: value pairs.  Each
    key consists of all of the recursed keys joined by
    separator.  If key_filter_callback is callable,
    it will be called with each key.  It should return
    either a new key which will be used in the final full
    key string, or False, which will indicate that this
    key and its value should be skipped.
    '''
    if parent_keys is None:
        parent_keys = []

    flattened = {}

    try:
        iterator = node.iteritems()
    except AttributeError:
        iterator = enumerate(node)

    for key, child in iterator:
        # If key_filter_callback was provided,
        # then call it on the key.  If the returned
        # key is false, then, we know to skip it.
        if callable(key_filter_callback):
            key = key_filter_callback(key)
        if key is False:
            continue

        # append this key to the end of all keys seen so far
        all_keys = parent_keys + [str(key)]

        if hasattr(child, '__iter__'):
            # merge the child items all together
            flattened.update(flatten_object(child, separator, key_filter_callback, all_keys))
        else:
            # '/' is  not allowed in key names.
            # Ganglia writes files based on key names
            # and doesn't escape these in the path.
            final_key = separator.join(all_keys).replace('/', separator)
            flattened[final_key] = child

    return flattened


def tail(filename, n=2):
    '''
    Tails the last n lines from filename and returns them in a list.
    '''

    cmd = '/usr/bin/tail -n {0} {1}'.format(n, filename)

    f = os.popen(cmd)
    lines = f.read().strip().split('\n')
    f.close()
    return lines


def infer_metric_type(value):
    '''
    Infers ganglia type from the
    variable type of value.
    '''
    if isinstance(value, float):
        metric_type = 'float'
    # use unint for int and long.
    # If bool, use 'string'. (bool is a subtype of int)
    elif isinstance(value, int) or isinstance(value, long):
        metric_type = 'uint'
    else:
        metric_type = 'string'

    return metric_type


class VarnishkafkaStats(object):
    '''
    Class representing most recent varnishkafka stats found
    in the varnishkafka.stats.json file.  Calling update_stats()
    will cause this class to read the most recent JSON objects from
    this file, and parse them into a flattened stats dict suitable
    for easy querying to send to ganglia.
    '''

    # Any key that ends with one of these
    # will cause this update_stats() to
    # calculate a rate of change for this stat
    # since the last run and insert it into
    # flattened_stats dict suffixed by
    # per_second_key_suffix.
    counter_stats = [
        'tx',
        'txbytes',
        'txerrs',
        'txmsgs',

        'rx',
        'rxbytes'
        'rxerrs',

        'kafka_drerr',
        'scratch_toosmall',
        'txerr',
        'trunc',
        'scratch_tmpbufs',
    ]

    per_second_key_suffix = 'per_second'

    def __init__(
            self,
            stats_file='/var/cache/varnishkafka/varnishkafka.stats.json',
            key_separator='.'):
        self.stats_file = stats_file
        self.key_separator = key_separator

        # NOTE:  It might be more elegant to
        # store the JSON object as it comes back from stats_file,
        # rather than keeping the state in the flattened hash.

        # latest flattnened stats as read from stats_file
        self.flattened_stats = {}
        # previous flattened stats as read from stats_file
        self.flattened_stats_previous = {}

        # varnishkafka outputs two types of distinct JSON objects
        # each time it outputs stats.  One is for varnishkafka stats,
        # the other is for librdkafka stats.  We will read this
        # many lines from the end of the stats file per gmond check.
        self.distinct_lines_per_interval = 2

        # timestamp keys from each distinct json object as
        # they will appear in the self.flattened_stats dict.
        # These are used for detecting changes in json data
        # in the stats_file.
        self.timestamp_keys = [
            key_separator.join(['kafka', 'varnishkafka', 'time']),
            key_separator.join(['kafka', 'rdkafka', 'time']),
        ]

    def key_filter(self, key):
        '''
        Filters out irrelevant varnishkafka metrics, and to transform
        the keys of some to make them more readable.
        '''

        # prepend appropriate rdkafka or varnishkafka to the key,
        # depending on where the metric has come from.
        if key == 'varnishkafka':
            key = self.key_separator.join(['kafka', 'varnishkafka'])
        elif key == 'kafka':
            key = self.key_separator.join(['kafka', 'rdkafka'])
        # don't send any bootstrap rdkafka metrics
        elif 'bootstrap' in key:
            return False
        # replace any key separators in the key with '-'
        elif self.key_separator in key:
            # this won't do anything if key_separator is '-'
            key = key.replace(self.key_separator, '-')
        # don't send anything that starts with -
        elif key.startswith('-'):
            return False

        return key

    def is_counter_stat(self, key):
        '''
        Returns true if this (flattened or leaf) key is a counter stat,
        meaning it should always increase during a varnishkafka instance's
        lifetime.
        '''
        return (key.split(self.key_separator)[-1] in self.counter_stats)

    def tail_stats_file(self):
        '''
        Returns the latest distinct_lines_per_interval lines from stats_file as a list.
        '''
        logger.info('Reading latest varnishkafka stats from {0}'.format(self.stats_file))
        return tail(self.stats_file, self.distinct_lines_per_interval)

    def get_latest_stats_from_file(self):
        '''
        Reads the latest stats out of stats_file and returns the parsed JSON object.
        '''
        lines = self.tail_stats_file()
        stats = {}
        for line in lines:
            stats.update(flatten_object(json.loads(line), self.key_separator, self.key_filter))

        return stats

    def update_stats(self, stats=None):
        '''
        Reads the latest stats out of stats_file and updates the stats
        attribute of this class.  If the data has changed since the last
        update, new counter rate of change per seconds stats will also be
        calculated.
        '''
        # Save the current stats into the previous stats
        # objects so we can compute rate of change over durations
        # for counter metrics.
        self.flattened_stats_previous = copy.deepcopy(self.flattened_stats)

        # If stats weren't manually passed, in, then go ahead and read the
        # most recent stats out of the stats_file.
        if not stats:
            stats = self.get_latest_stats_from_file()
        self.flattened_stats.update(stats)

        # If the stats we have now have actually changed since the
        # last time we updated the stats, then go ahead and compute
        # new per_second change rates for each counter stat.
        if self.have_stats_changed_since_last_update():
            logger.debug('varnishkafka stats have changed since last update.')
            self.update_counter_rate_stats()
        else:
            logger.debug('varnishkafka stats have not changed since last update.')

    def stat_rate_of_change(self, key):
        '''
        Given a value for stat key name, computes
        (current stat - previous stat) / update interval.
        Update interval is computed from the timestamp that comes with the
        JSON stats, not the time since update_stats() was last called.
        '''
        # The timestamp will be keyed as 'kafka.rdkafka.time' or 'kafka.varnishkafka.time',
        # depending on whether this is a librdkafka or a varnishkafka related stat.
        timestamp_key = self.key_separator.join(key.split(self.key_separator)[0:2] + ['time'])

        # if we don't yet have a previous value from which to calculate a
        # rate, just return 0 for now
        if (not self.flattened_stats or not self.flattened_stats_previous or
                timestamp_key not in self.flattened_stats_previous):
            return 0.0

        interval = self.flattened_stats[timestamp_key] - \
            self.flattened_stats_previous[timestamp_key]
        # if the timestamps are the same, then just return 0.
        if interval == 0:
            return 0.0

        # else calculate the per second rate of change
        return (self.flattened_stats[key] - self.flattened_stats_previous[key]) / interval

    def update_counter_rate_stats(self):
        '''
        For each counter stat, this will add an extra stat
        to the stats for rate of change per second.
        '''
        for key in filter(self.is_counter_stat, self.flattened_stats.keys()):
            per_second_key = self.key_separator.join([key, self.per_second_key_suffix])
            rate = self.stat_rate_of_change(key)
            self.flattened_stats[per_second_key] = rate

    def have_stats_changed_since_last_update(self):
        '''
        Returns true if either of the timestamp keys in the stats objects
        differ from the timestamp keys in the previously collected stats object.
        '''

        if not self.flattened_stats or not self.flattened_stats_previous:
            return True

        for key in self.timestamp_keys:
            if self.flattened_stats[key] != self.flattened_stats_previous[key]:
                return True

        return False
#
# Gmond Interface
#


# global VarnishkafkaStats object, will be
# instantiated by metric_init()
varnishkafka_stats = None
time_max = 15
last_run_timestamp = 0
key_prefix = ''


def metric_handler(name):
    """Get value of particular metric; part of Gmond interface"""
    global varnishkafka_stats
    global time_max
    global last_run_timestamp
    global key_prefix

    name = name[len(key_prefix):]
    seconds_since_last_run = time.time() - last_run_timestamp
    if (seconds_since_last_run >= time_max):
        logger.debug(
            'Updating varnishkafka_stats since it has been {0} seconds, which '
            'is more than tmax of {1}'.format(seconds_since_last_run, time_max))
        varnishkafka_stats.update_stats()
        last_run_timestamp = time.time()

    logger.debug('metric_handler called for {0}, value: {1}'.format(
        name, varnishkafka_stats.flattened_stats[name]))
    return varnishkafka_stats.flattened_stats[name]


def metric_init(params):
    """Initialize; part of Gmond interface"""
    global varnishkafka_stats
    global time_max
    global last_run_timestamp
    global key_prefix

    stats_file = params.get('stats_file', '/var/cache/varnishkafka/varnishkafka.stats.json')
    key_separator = params.get('key_separator', '.')
    time_max = int(params.get('tmax', time_max))
    key_prefix = params.get('key_prefix', '')
    if key_prefix and not key_prefix.endswith(key_separator):
        key_prefix += key_separator
    default_group = '_'.join(('varnishkafka', key_prefix)).strip(key_separator + '_')
    ganglia_groups = params.get('groups', default_group)

    varnishkafka_stats = VarnishkafkaStats(stats_file, key_separator)
    # Run update_stats() so that we'll have a list of stats keys that will
    # be sent to ganglia.  We can use this to build the descriptions dicts
    # that metric_init is supposed to return.
    # NOTE:  This requires that the stats file already have some data in it.
    varnishkafka_stats.update_stats()
    last_run_timestamp = time.time()

    descriptions = []

    # Iterate through the initial set of stats and create
    # dictionary objects for each.
    for key, value in varnishkafka_stats.flattened_stats.items():
        # skip any keys that are in skip_metrics
        if key.split(key_separator)[-1] in skip_metrics:
            continue

        # value_type must be one of
        # string | uint | float | double.
        metric_type = infer_metric_type(value)
        # if value is a bool, then convert it to an int
        if isinstance(value, bool):
            value = int(value)

        if metric_type == 'uint':
            metric_format = '%d'
        elif metric_type == 'float' or metric_type == 'double':
            metric_format = '%f'
        else:
            metric_format = '%s'

        # Try to infer some useful units from the key name.
        if key.endswith('bytes'):
            metric_units = 'bytes'
        elif key.endswith('tx'):
            metric_units = 'transmits'
        elif key.endswith('rx'):
            metric_units = 'receives'
        elif key.endswith('msgs'):
            metric_units = 'messages'
        elif key.endswith('err') or key.endswith('errs'):
            metric_units = 'errors'
        elif 'rtt' in key and 'cnt' not in key:
            metric_units = 'microseconds'
        else:
            metric_units = ''
        if key.endswith(varnishkafka_stats.per_second_key_suffix):
            metric_units = ' '.join([metric_units, 'per second'])

        descriptions.append({
            'name':         key_prefix + key,
            'call_back':    metric_handler,
            'time_max':     time_max,
            'value_type':   metric_type,
            'units':        metric_units,
            'slope':        'both',
            'format':       metric_format,
            'description':  '',
            'groups':       ganglia_groups,
        })

    return descriptions


def metric_cleanup():
    """Teardown; part of Gmond interface"""
    pass


# To run tests:
#   python -m unittest varnishkafka_ganglia
import unittest  # noqa


class TestVarnishkafkaGanglia(unittest.TestCase):

    def setUp(self):
        self.key_separator = '&'
        self.varnishkafka_stats = VarnishkafkaStats(
            '/tmp/test-varnishkafka.stats.json', self.key_separator)

        self.json_data = {
            '1.1': {
                'value1': 0,
                'value2': 'hi',
                '1.2': {
                    'value3': 0.1,
                    'value4': False,
                }
            },
            '2.1': ['a', 'b'],
            # '/' should be replaced with key_separator
            '3/1': 'nonya',
            'notme': 'nope',
            'kafka': {
                'varnishkafka': {
                    'time': time.time(),
                    'counter': {self.varnishkafka_stats.counter_stats[0]: 0},
                },
                'rdkafka': {'time': time.time()}
            },
        }
        self.flattened_should_be = {
            '1.1&value1': 0,
            '1.1&valuetwo': 'hi',
            '1.1&1.2&value3': 0.1,
            '1.1&1.2&value4': False,
            '2.1&0': 'a',
            '2.1&1': 'b',
            # '/' should be replaced with key_separator
            '3&1': 'nonya',
            'kafka&varnishkafka&time': self.json_data['kafka']['varnishkafka']['time'],
            'kafka&varnishkafka&counter&{0}'.format(self.varnishkafka_stats.counter_stats[0]): 0,
            'kafka&rdkafka&time': self.json_data['kafka']['rdkafka']['time'],
        }

    def key_filter_callback(self, key):
        if key == 'value2':
            key = 'valuetwo'
        if key == 'notme':
            key = False

        return key

    def test_flatten_object(self):
        flattened = flatten_object(self.json_data, self.key_separator, self.key_filter_callback)
        self.assertEquals(flattened, self.flattened_should_be)

    def test_is_counter_stat(self):
        self.assertTrue(self.varnishkafka_stats.is_counter_stat(
            self.varnishkafka_stats.counter_stats[0]))
        self.assertTrue(self.varnishkafka_stats.is_counter_stat(
            'whatever&it&no&matter&' + self.varnishkafka_stats.counter_stats[0]))
        self.assertFalse(self.varnishkafka_stats.is_counter_stat('notone'))

    def test_update_stats(self):
        self.varnishkafka_stats.update_stats(self.flattened_should_be)
        self.assertEquals(self.varnishkafka_stats.flattened_stats[
                          '1.1&valuetwo'], self.flattened_should_be['1.1&valuetwo'])

        previous_value = self.varnishkafka_stats.flattened_stats['1.1&valuetwo']
        self.flattened_should_be['1.1&valuetwo'] = 1
        self.varnishkafka_stats.update_stats(self.flattened_should_be)
        self.assertEquals(self.varnishkafka_stats.flattened_stats[
                          '1.1&valuetwo'], self.flattened_should_be['1.1&valuetwo'])
        self.assertEquals(self.varnishkafka_stats.flattened_stats_previous[
                          '1.1&valuetwo'], previous_value)

    def test_rate_of_change_update_stats(self):
        counter_key = 'kafka{0}varnishkafka{0}counter{0}{1}'.format(
            self.key_separator, self.varnishkafka_stats.counter_stats[0])
        self.varnishkafka_stats.update_stats(self.flattened_should_be)
        previous_value = self.flattened_should_be[counter_key]

        # increment the counter and the timestamp to make VarnishkafkaStats
        # calculate a new per_second rate
        self.flattened_should_be[counter_key] += 101
        self.flattened_should_be['kafka&varnishkafka&time'] += 100.0
        self.varnishkafka_stats.update_stats(self.flattened_should_be)

        self.assertEquals(
            self.varnishkafka_stats.flattened_stats_previous[counter_key],
            previous_value
        )
        self.assertEquals(
            self.varnishkafka_stats.flattened_stats[counter_key],
            self.flattened_should_be[counter_key]
        )
        self.assertEquals(
            self.varnishkafka_stats.flattened_stats['kafka&varnishkafka&time'],
            self.flattened_should_be['kafka&varnishkafka&time']
        )
        per_second_key = self.key_separator.join(
            [counter_key, self.varnishkafka_stats.per_second_key_suffix])

        rate_should_be = (
            self.flattened_should_be[counter_key] -
            self.varnishkafka_stats.flattened_stats_previous[counter_key]) / 100.0
        self.assertEquals(self.varnishkafka_stats.flattened_stats[per_second_key], rate_should_be)


def generate_pyconf(
        module_name, metric_descriptions, params={}, collect_every=15, time_threshold=15):
    '''
    Generates a pyconf file including all of the metrics in metric_descriptions.
    '''

    params_string = ''
    params_keys = params.keys()
    params_keys.sort()
    for key in params_keys:
        value = params[key]
        if isinstance(value, str):
            value = '"{0}"'.format(value)
        else:
            value = str(value)
        params_string += '    param %s { value = %s }\n' % (key, value)

    key_prefix = params.get('key_prefix', '')
    key_separator = params.get('key_separator', '.')
    if key_prefix and not key_prefix.endswith(key_separator):
        key_prefix += key_separator

    metrics_string = ''
    metric_descriptions.sort()
    for description in metric_descriptions:
        metrics_string += """
  metric {
    name  = "%(name)s"
  }
""" % description

    return """# %(module_name)s plugin for Ganglia Monitor, automatically generated config file
modules {
  module {
    name = "%(module_name)s"
    language = "python"
%(params_string)s
  }
}
collection_group {
  collect_every = %(collect_every)s
  time_threshold = %(time_threshold)s
%(metrics_string)s
}
""" % {'module_name': module_name,
       'params_string': params_string,
       'collect_every': collect_every,
       'time_threshold': time_threshold,
       'metrics_string': metrics_string
       }


if __name__ == '__main__':
    # When invoked as standalone script, run a self-test by querying each
    # metric descriptor and printing it out.

    cmdline = optparse.OptionParser(usage="usage: %prog [options] statsfile")
    cmdline.add_option(
        '--generate-pyconf', '-g', dest='pyconf', metavar='FILE',
        help='If set, a .pyconf file will be output with flattened metrics key from statsfile.')
    cmdline.add_option(
        '--tmax', '-t', action='store', default=15,
        help='time_max for ganglia python module metrics.')
    cmdline.add_option(
        '--key-separator', '-k', dest='key_separator', default='.',
        help=(
            'Key separator for flattened json object key name. '
            "Default: '.'  '/' is not allowed."))
    cmdline.add_option(
        '--key-prefix', '-p', dest='key_prefix', default='',
        help='Optional key prefix for flattened json object key name.')
    cmdline.add_option('--dry-run', action='store_true', default=False)
    cmdline.add_option(
        '--debug', '-D', action='store_true', default=False,
        help='Provide more verbose logging for debugging.')

    cli_options, arguments = cmdline.parse_args()

    if (len(arguments) != 1):
        cmdline.print_help()
        cmdline.error("Must supply statsfile argument.")

    cli_options.stats_file = arguments[0]

    # Turn the optparse.Value object into a regular dict
    # so we can pass it to metric_init
    params = vars(cli_options)

    # If we are to generate the pyconf file from
    # data in stats_file, do so now.
    if cli_options.pyconf:
        try:
            with open(cli_options.pyconf, 'r') as f:
                cur_pyconf = f.readlines()
        except Exception:
            cur_pyconf = []

        new_pyconf = generate_pyconf(
            'varnishkafka',
            metric_init(params),
            # set stats_file and tmax from cli options
            {
                'tmax': cli_options.tmax,
                'stats_file': cli_options.stats_file,
            },
            # collect_every == tmax
            cli_options.tmax,
            # time_threshold == tmax
            cli_options.tmax,
        ).splitlines(True)

        diff = list(difflib.unified_diff(cur_pyconf, new_pyconf,
                                         fromfile=cli_options.pyconf,
                                         tofile=cli_options.pyconf))
        for line in diff:
            print line,

        if not diff:
            print 'Nothing to do: %s is up-to-date.' % cli_options.pyconf
            sys.exit(1)

        if not len(''.join(new_pyconf).strip()):
            print 'Nothing to do.'
            sys.exit(1)

        if not cli_options.dry_run:
            with open(cli_options.pyconf, 'w') as f:
                f.writelines(new_pyconf)

        print '\nWrote "%s".' % cli_options.pyconf
        sys.exit(0)

    # Else print out values of metrics in a loop.
    else:
        # use logger to print to stdout
        stdout_handler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s')
        stdout_handler.setFormatter(formatter)
        logger.addHandler(stdout_handler)

        if (cli_options.debug):
            logger.setLevel(logging.DEBUG)

        metric_descriptions = metric_init(params)
        while True:
            print('----------')
            for metric in metric_descriptions:
                value = metric['call_back'](metric['name'])
                print("{0} => {1} {2}".format(metric['name'], value, metric['units']))
            time.sleep(float(params['tmax']))
