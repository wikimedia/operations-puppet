#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import argparse
import json
import socket
import unittest
import yaml

from kafka import KafkaConsumer


def handle_edit(meta):
    event = meta['event']
    if event['editor'] == 'visualeditor':
        action = event['action']
        if action == 'saveSuccess':
            metric = 'save'
        elif action == 'ready':
            metric = 'load'
        else:
            return
        timing = int(event['action.%s.timing' % action])
        # Log values between 0.1s an 100s (1.6min) only
        if timing < 100 or timing > 100000:
            return
        return 'VisualEditor.%s:%s|ms' % (metric, timing)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description='Send VisualEditor PerfData to StatsD')
    ap.add_argument('--brokers', required=True,
                    help='Comma-separated list of kafka brokers')
    ap.add_argument('--consumer-group', required=True,
                    help='Consumer group to register with Kafka')
    ap.add_argument('--statsd-host', default='localhost',
                    type=socket.gethostbyname)
    ap.add_argument('--statsd-port', default=8125, type=int)
    args = ap.parse_args()

    addr = args.statsd_host, args.statsd_port
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    kafka_bootstrap_servers = tuple(args.brokers.split(','))
    kafka_topic = 'eventlogging_Edit'
    kafka_consumer_timeout_seconds = 600
    consumer = KafkaConsumer(
        kafka_topic,
        bootstrap_servers=kafka_bootstrap_servers,
        group_id=args.consumer_group,
        auto_offset_reset='latest',
        enable_auto_commit=False,
        consumer_timeout_ms=kafka_consumer_timeout_seconds * 1000
    )

    try:
        for message in consumer:
            meta = json.loads(message.value)
            try:
                stat = handle_edit(meta)
                if stat is not None:
                    sock.sendto(stat.encode('utf-8'), addr)
            except (ValueError, KeyError):
                continue
        # If we reach this line, consumer_timeout_ms elapsed without events
        raise RuntimeError('No messages received in %d seconds.' % kafka_consumer_timeout_seconds)
    finally:
        consumer.close()


# ##### Tests ######
# To run:
#   python -m unittest ve
#
class TestVePerfData(unittest.TestCase):
    def test_handler(self):
        with open('ve_fixture.yaml') as fixture_file:
            fixture = yaml.safe_load(fixture_file)
            actual = []
            for meta in fixture:
                stat = handle_edit(meta)
                if stat is not None:
                    actual.append(stat)
            with open('ve_expected.txt') as expected_file:
                self.assertItemsEqual(
                    actual,
                    expected_file.read().splitlines()
                )
