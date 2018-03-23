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
import collections
from kafka import KafkaConsumer
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
        self.windows = collections.defaultdict(list)
        self.now = time.time()  # make it possible to be in the past
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

    def handle_event(self, meta):
        if 'schema' not in meta:
            self.log.warning('Message received with no schema defined')
            return None

        if meta['schema'] not in ('NavigationTiming', 'SaveTiming'):
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

        event = meta['event']
        for metric in METRICS:
            value = event.get(metric)
            if value:
                window = self.windows[metric]
                window.append((timestamp, value))
        return timestamp

    def flush_data(self):
        self.log.debug('Flushing data')
        for metric, window in sorted(self.windows.items()):
            if len(window) == 0:
                continue

            window.sort()
            # Always start with the oldest sample
            first_timestamp = int(window[0][0])

            while True:
                messages_deleted = 0

                # Establish a sample period that begins with the oldest sample
                end_timestamp = first_timestamp + WINDOW_SPAN

                # There's no way to know that all of the data for the current window
                # has been collected, so push on and process next interval.
                if end_timestamp > int(window[-1][0]):
                    self.log.debug('Last message timestamp {}, current window ends at {}'.format(
                        int(window[-1][0]), end_timestamp))
                    break

                # Write the value of this window to the whisper file
                values = [value for timestamp, value in window if timestamp <= end_timestamp]
                if len(values) == 0:
                    self.log.info('[{}] No metrics in window {} to {}'.format(
                        metric, first_timestamp, end_timestamp))
                    # jump to the next window
                    first_timestamp += UPDATE_INTERVAL
                    continue
                current_value = self.median(values)
                if self.args.dry_run:
                    self.log.info('[{}] [{}] {}'.format(metric, end_timestamp,
                                  current_value))
                else:
                    self.log.info('[{}] {} values found between {} and {}: median {}'.format(
                        metric, len(values), first_timestamp, end_timestamp,
                        current_value))
                    whisper.update(self.get_whisper_file(metric), current_value,
                                   timestamp=end_timestamp)

                # Get rid of the first interval worth of items from the window
                for item in [item for item in window
                             if item[0] < (first_timestamp + UPDATE_INTERVAL)]:
                    window.remove(item)
                    messages_deleted += 1
                self.log.info('[{}] Removed {} data points between {} and {}'.format(
                    metric, messages_deleted, first_timestamp, first_timestamp + UPDATE_INTERVAL))

                # Move to the next window and loop again
                first_timestamp += UPDATE_INTERVAL

    def run(self):
        window_start = time.time()
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
                    consumer_timeout_ms=UPDATE_INTERVAL * 1000)
                self.log.info('Subscribing to topics: {}'.format(self.args.topics))
                consumer.subscribe(self.args.topics)

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

                        # Get the incoming event on to the pile.  Get back the
                        # event timestamp.  If the timestamp is old (likely because
                        # we had a queue of old messages to handle), then reset the
                        # window start value.
                        event_ts = self.handle_event(value)
                        if event_ts is None:
                            continue

                        if event_ts < window_start:
                            window_start = event_ts
                        else:
                            if (event_ts - WINDOW_SPAN - UPDATE_INTERVAL) > window_start:
                                # We've received a message that's more than WINDOW_SPAN +
                                # UPDATE_INTERVAL seconds later than the start of the
                                # current window, so time to flush.
                                self.flush_data()
                                window_start = window_start + UPDATE_INTERVAL

            # Allow for a clean quit on interrupt
            except KeyboardInterrupt:
                self.log.info('Stopping the Kafka consumer and shutting down')
                try:
                    consumer.close()
                except Exception:
                    self.log.exception('Exception closing consumer, shutting down anyway')
                break
            except IOError:
                self.log.exception('Error in main loop, restarting consumer')
            except Exception:
                self.log.exception('Unhandled exception caught, restarting consumer')
            finally:
                try:
                    # Take a stab at flushing any remaining data, just in case
                    self.flush_data()
                    consumer.close()
                except Exception:
                    self.log.exception('Exception closing consumer')


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--brokers', required=True,
                            help='Comma-separated list of Kafka brokers')
    arg_parser.add_argument('--consumer-group', required=True,
                            dest='consumer_group', help='Name of the Kafka consumer group')
    arg_parser.add_argument('--topic', required=True, action='append',
                            dest='topics', help='Kafka topic from which to consume')
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
