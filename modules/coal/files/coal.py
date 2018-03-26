#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
  coal
  ~~~~
  Coal logs Navigation Timing metrics to Whisper files.

  More specifically, coal aggregates all of the samples for a given NavTiming
  metric that are collected within a period of time, and it writes the median
  of those values to Whisper files.

  See the constants at the top of the file for configuration options.

  Copyright 2015 Ori Livneh <ori@wikimedia.org>
  Copyright 2018 Ian Marlier <imarlier@wikimedia.org>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

"""
import argparse
from kafka import KafkaConsumer, TopicPartition
from kafka.structs import OffsetAndMetadata
import dateutil.parser
import json
import logging
import os
import os.path
import time
import whisper


UPDATE_INTERVAL = 60  # How often we log values, in seconds
WINDOW_SPAN = UPDATE_INTERVAL * 5  # Size of sliding window, in seconds.
RETENTION = 525949    # How many datapoints we retain. (One year's worth.)
METRICS = (
    'connectEnd',
    'connectStart',
    'dnsLookup',
    'domainLookupStart',
    'domainLookupEnd',
    'domComplete',
    'domContentLoadedEventStart',
    'domContentLoadedEventEnd',
    'domInteractive',
    'fetchStart',
    'firstPaint',
    'loadEventEnd',
    'loadEventStart',
    'mediaWikiLoadComplete',
    'mediaWikiLoadStart',
    'mediaWikiLoadEnd',
    'redirectCount',
    'redirecting',
    'redirectStart',
    'redirectEnd',
    'requestStart',
    'responseEnd',
    'responseStart',
    'saveTiming',
    'secureConnectionStart',
    'unloadEventStart',
    'unloadEventEnd',
)
ARCHIVES = [(UPDATE_INTERVAL, RETENTION)]


class WhisperLogger(object):
    def __init__(self, args):
        self.args = args

        # Log config
        self.log = logging.getLogger(__name__)
        self.log.setLevel(logging.DEBUG if self.args.verbose else logging.INFO)
        ch = logging.StreamHandler()
        ch.setLevel(logging.DEBUG if self.args.verbose else logging.INFO)
        formatter = logging.Formatter(
            '%(asctime)s [%(levelname)s] (%(funcName)s:%(lineno)d) %(msg)s')
        formatter.converter = time.gmtime
        ch.setFormatter(formatter)
        self.log.addHandler(ch)

        #
        # events is a dict, of dicts.  The keys are the schemas that we're working
        # with.  It's necessary to operate at the schema level because the data
        # for each event type is on a seperate Kafka topic, and we may be at very
        # different locations on each topic.
        #
        # The key for each item in events is a timestamp that is aligned to the
        # minute boundary.  That is:
        #     key = timestamp - (timestamp % 60)
        #
        # Each item is itself a dict, whose keys are the names of metrics.  Each
        # of those is a list of values collected for that metric within the window,
        # where the window is defined as
        #     minute_boundary <= timestamp < (minute_boundary + UPDATE_INTERVAL)
        #
        # Thus, the resulting events dict will look something like this:
        # events = {
        #       'NavigationTiming': {
        #           1522072560: {
        #               'connectEnd': [1, 2, 5, 9, 2, 3],
        #               'connectStart': [1, 1, 1, 1, 1],
        #               .....
        #           },
        #           1522072620: {
        #               'connectEnd': [.......],
        #               .....
        #           },
        #       },
        #       'SaveTiming': {
        #           1522072560: {....},
        #           ....
        #       }
        #   }
        self.events = {}
        for schema in self.args.schemas:
            self.events[schema] = {}

        #
        # offsets is a dict whose keys are schema names.  Each is itself a dict,
        # whose keys are timestamps aligned to the minute boundary, as with events.
        # However, the content of each key is a single value representing the
        # highest kafka offset seen within that boundary.
        #
        self.offsets = {}
        for schema in self.args.schemas:
            self.offsets[schema] = {}

        #
        # Keep a timestamp that tracks the last time we flushed the recorded
        # values for each schema
        #
        self.last_window_flushed = {}
        for schema in self.args.schemas:
            self.last_window_flushed[schema] = int(time.time() - (time.time() % 60))

    def topic(self, schema):
        return 'eventlogging_{}'.format(schema)

    def median(self, population):
        population = list(sorted(population))
        length = len(population)
        if length == 0:
            raise ValueError('Cannot compute median of empty list.')
        index = (length - 1) // 2
        if length % 2:
            return population[index]
        middle_terms = population[index] + population[index + 1]
        return middle_terms / 2.0

    def get_whisper_file(self, metric):
        return os.path.join(self.args.whisper_dir, metric + '.wsp')

    def create_whisper_files(self):
        if self.args.dry_run:
            self.log.info(
                'Skipping creating whisper files because dry-run flag is set')
            return
        for metric in METRICS:
            try:
                whisper.create(self.get_whisper_file(metric), ARCHIVES)
            except whisper.InvalidConfiguration:
                pass  # Already exists.

    #
    # Process an incoming event
    #
    # Parameters:
    #   meta: event dict (post JSON decoding)
    #
    # Returns:
    #   None if no offsets need to be commited, or int representing the max offset flushed
    #
    def handle_event(self, meta, offset):
        if 'schema' in meta:
            schema = meta['schema']
        else:
            self.log.warning('Message received with no schema defined')
            return None

        if schema not in self.args.schemas:
            self.log.warning('Message received with invalid schema')
            return None

        # dt is main EventCapsule timestamp field in ISO-8601
        if 'dt' in meta:
            timestamp = int(dateutil.parser.parse(meta['dt']).strftime("%s"))
        # timestamp is backwards compatible int, this shouldn't be used anymore.
        elif 'timestamp' in meta:
            timestamp = meta['timestamp']
        # else we can't find one, just use the current time.
        else:
            self.log.warning('Message received with no timestamp')
            return None

        if 'event' not in meta:
            self.log.warning('No event data contained in message')
            return None

        minute_boundary = int(timestamp - (timestamp % UPDATE_INTERVAL))
        if minute_boundary not in self.events[schema]:
            self.log.debug('[{}] Adding boundary at {}'.format(schema, minute_boundary))
            self.events[schema][minute_boundary] = {}

        event = meta['event']
        for metric in METRICS:
            value = event.get(metric)
            if value:
                if metric not in self.events[schema][minute_boundary]:
                    self.events[schema][minute_boundary][metric] = []
                self.events[schema][minute_boundary][metric].append(value)

        # If this offset is the highest that we know about for this boundary,
        # record it.
        if minute_boundary not in self.offsets:
            self.offsets[schema][minute_boundary] = offset
        else:
            if offset > self.offsets[schema][minute_boundary]:
                self.offsets[schema][minute_boundary] = offset

        #
        # Figure out whether to process the collected data, based on the timestamp
        # Of the message being processed.  The idea here is that timestamp will
        # be generally increasing.  Not monotonically, but close enough to
        # monotonically that we can fudge it by waiting an entra UPDATE_INTERVAL
        # before processing each WINDOW_SPAN.
        #
        # Generally speaking, what this means is that events will have 6 active
        # windows:
        #   events = {
        #       1522072560: {},
        #       1522072620: {},
        #       1522072680: {},
        #       1522072740: {},
        #       1522072800: {},
        #       1522072860: {}
        #   }
        #
        # As soon as a message is received that causes a new window to be created,
        # the first 5 of these 6 windows will be processed.  The resulting data
        # points will use the timestamp 1522072800.  Then, the dict with timestamp
        # 1522072560 will be deleted.
        #
        # events then looks like this:
        #   events = {
        #       1522072620: {},
        #       1522072680: {},
        #       1522072740: {},
        #       1522072800: {},
        #       1522072860: {},
        #       1522072920: {}
        #   }
        #
        if (timestamp - WINDOW_SPAN) > self.last_window_flushed[schema]:
            return self.flush_data(schema)

    #
    # Flush the data that's been collected to graphite.  Commit the appropriate
    # Kafka offsets so that if we restart, we don't re-process them.  The offsets
    # committed will be only those in the oldest UPDATE_INTERVAL of WINDOW_SPAN
    #
    # NB: This function is intentionally written in such a way that it can easily
    # be called from either handle_event, or from an async timer function, thus
    # some of the extra sanity checking around boundary lengths and the like
    #
    # Parameters:
    #   schema: string name of the schema that this message belongs to
    #
    # Returns:
    #   None if there's no offsets to commit, int otherwise
    #
    def flush_data(self, schema):
        self.log.debug('Flushing data for schema {}'.format(schema))

        offset_to_return = None

        while True:
            #
            # Start with the oldest minute_boundary value, since it's possible
            # that we're catching up
            #
            sorted_boundaries = sorted(self.events[schema].keys())

            if len(sorted_boundaries) == 0:
                self.log.info('No data to process')
                return offset_to_return

            oldest_boundary = sorted_boundaries[0]

            #
            # We don't want to flush the data that we've accumulated if there's a
            # chance that we might still get data in one of the relevant windows.
            #
            # We're (relatively) naively assuming that UPDATE_INTERVAL is enough
            # time to wait for any lagged messages, so we want to be sure that
            # it's been at least UPDATE_INTERVAL + WINDOW_SPAN since the oldest
            # boundary.
            #
            if (oldest_boundary + WINDOW_SPAN + UPDATE_INTERVAL) > time.time():
                self.log.debug('All windows with sufficient data have been processed')
                return offset_to_return

            #
            # If we get here, we know that we have at least one window that can be
            # processed.
            #
            # Start by creating a list of the timestamps that are within the current
            # window.
            #
            boundaries_to_consider = [boundary for boundary in sorted_boundaries if
                                      boundary < (oldest_boundary + WINDOW_SPAN)]
            self.log.info('[{}] Processing events in boundaries [{}]'.format(
                                                schema, boundaries_to_consider))

            # Make a dict of the metrics that have samples within this window, and
            # put all of the collected samples into a list.  Don't assume that every
            # metric present in the window is in the first boundary.
            metrics_with_samples = {}
            for boundary in boundaries_to_consider:
                for metric in self.events[schema][boundary]:
                    if metric not in metrics_with_samples:
                        metrics_with_samples[metric] = []
                    metrics_with_samples[metric].extend(self.events[schema][boundary][metric])

            # Get the median for each metric and write:
            for metric, values in metrics_with_samples.items():
                median_value = self.median(values)
                if self.args.dry_run:
                    self.log.info('[{}] [{}] {}'.format(metric,
                                                        oldest_boundary + WINDOW_SPAN,
                                                        median_value))
                    # If this is a dry run, we don't want to actually commit, but
                    self.log.debug('[{}] Dry run, so not actually committing to offset {}'.format(
                                            schema, self.offsets[schema][oldest_boundary]))
                    offset_to_return = None
                else:
                    whisper.update(self.get_whisper_file(metric), median_value,
                                   timestamp=oldest_boundary + WINDOW_SPAN)
                    #
                    # Last thing to do is to commit the oldest offsets to Kafka, and then
                    # delete the oldest boundary from the events and offsets dicts
                    #
            offset_to_return = None if self.args.dry_run else self.offsets[schema][oldest_boundary]
            del self.events[schema][oldest_boundary]
            del self.offsets[schema][oldest_boundary]
            if oldest_boundary > self.last_window_flushed[schema]:
                self.last_window_flushed[schema] = oldest_boundary
        return offset_to_return

    def commit(self, consumer, topic, offset):
        consumer.commit({
            TopicPartition(topic=topic, partition=0):
                OffsetAndMetadata(offset=offset, metadata=None)
            })

    def run(self):
        self.create_whisper_files()

        # There are basically 3 ways to handle timers
        #  1. On each received Kafka message, check whether we've tipped over into
        #     the next window, and if so, do processing.  The problem with this
        #     is that if no message is received for some period of time, then
        #     processing never happens.
        #  2. Run the Kafka poller in one thread, and the timer in another.  Use
        #     a lock to temporarily block the poller while processing is happening.
        #     While this is pretty straightforward, it does require dealing with
        #     threads and shared vars.
        #  3. Run the poller inside of one aio function, and the timer inside of
        #     another.  Leave it to asyncio to handle the coordination.  This is,
        #     honestly, the most complete and easiest to reason about of these
        #     solutions.  But it also requires py >= 3.4, aiokafka, and potentially
        #     other aio libraries that aren't packaged natively.
        #
        # This method, as written, implements #1.
        while True:
            try:
                self.log.info('Starting Kafka connection to brokers ({}).'.format(
                    self.args.brokers))
                consumer = KafkaConsumer(
                    bootstrap_servers=self.args.brokers,
                    group_id=self.args.consumer_group,
                    enable_auto_commit=False)

                # Work out topic names based on schemas, and subscribe to the
                # appropriate topics
                topics = [self.topic(schema) for schema in self.args.schemas]
                self.log.info('Subscribing to topics: {}'.format(topics))
                consumer.subscribe(topics)

                self.log.info('Beginning poll cycle')

                for message in consumer:
                    # Message was received
                    if 'error' in message:
                        self.log.error('Kafka error: {}'.format(message.error))
                    else:
                        try:
                            value = json.loads(message.value)
                        except ValueError:
                            # If incoming messages aren't well-formatted, log them
                            # so we can see that and handle it.
                            self.log.error(
                                'ValueError raised trying to load JSON message: %s',
                                message.value())
                            continue

                        # If this is an oversample, then skip it
                        if 'event' in value and 'is_oversample' in value['event'] and \
                                                value['event']['is_oversample']:
                            continue

                        # Get the incoming event on to the pile, and if necessary,
                        # get back the offset that we need to commit to Kafka
                        offset_to_commit = self.handle_event(value, message.offset)
                        if offset_to_commit is None:
                            continue

                        # Need to commit!
                        self.log.info('[{}] Committing offset {}'.format(
                                        schema, offset_to_commit))
                        self.commit(consumer, message.topic, offset_to_commit)
                        self.log.debug('Committed')

            # Allow for a clean quit on interrupt
            except KeyboardInterrupt:
                self.log.info('Stopping the Kafka consumer and shutting down')
                try:
                    # Take a stab at flushing any remaining data, just in case
                    self.log.info('Trying to commit any last data before exit')
                    for schema in self.args.schemas:
                        offset_to_commit = self.flush_data(schema)
                        if offset_to_commit is not None:
                            self.commit(consumer, schema, offset_to_commit)
                    consumer.close()
                except Exception:
                    self.log.exception('Exception closing consumer')
                break
            except IOError:
                self.log.exception('Error in main loop, restarting consumer')
            except Exception:
                self.log.exception('Unhandled exception caught, restarting consumer')


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--brokers', required=True,
                            help='Comma-separated list of Kafka brokers')
    arg_parser.add_argument('--consumer-group', required=True,
                            dest='consumer_group', help='Name of the Kafka consumer group')
    arg_parser.add_argument('--schema', required=True, action='append',
                            dest='schemas',
                            help='Schemas that we deal with, topic names are derived')
    arg_parser.add_argument('--whisper-dir', default=os.getcwd(),
                            required=False,
                            help='Path for Whisper files.  Defaults to current working dir')
    arg_parser.add_argument('-n', '--dry-run', required=False, dest='dry_run',
                            action='store_true', default=False,
                            help='Don\'t create whisper files, just output')
    arg_parser.add_argument('-v', '--verbose', dest='verbose',
                            required=False, default=False, action='store_true',
                            help='Increase verbosity of output')
    args = arg_parser.parse_args()
    app = WhisperLogger(args)
    app.run()
