# -*- coding: utf-8 -*-
"""
  Kafka writer plug-in for EventLogging

  Requires kafka-python: <https://github.com/mumrah/kafka-python>.

  Copyright (C) 2013, Ori Livneh <ori@wikimedia.org>
  Licensed under the terms of the GPL, version 2 or later.

"""
from kafka.client import KafkaClient
from kafka.producer import KeyedProducer


@writes('kafka')
def kafka_writer(hostname, port, topic='eventlogging', **kwargs):
    """Write events to Kafka, keyed by SCID."""
    kafka = KafkaClient(hostname, port)
    producer = KeyedProducer(kafka, topic, **kwargs)

    while 1:
        event = (yield)
        key = '%(schema)s_%(revision)s' % event  # e.g. 'EchoMail_5467650'
        producer.send(key, json.dumps(event, sort_keys=True))
