#!/usr/bin/env python

from confluent_kafka import Producer
import copy
import json
import random


baseline = {
	'schema': 'NavigationTiming',
	'timestamp': 1519922294,
	'event': {
		'connectEnd': 123,
		'connectStart': 121,
		'domComplete': 1234,
		'loadEventStart': 253,
		'loadEventEnd': 1234
	}
}

events = []
for n in range(0, 1000):
	event = copy.deepcopy(baseline)
	event['timestamp'] = event['timestamp'] + random.randint(0, 150)
	event['event']['connectEnd'] += random.randint(-30, 30)
	event['event']['connectStart'] = event['event']['connectEnd'] - random.randint(0, 30)
	event['event']['domComplete'] += random.randint(-100, 100)
	event['event']['loadEventStart'] += random.randint(-50, 50)
	event['event']['loadEventEnd'] = event['event']['domComplete']
	events.append(event)

producer = Producer({'bootstrap.servers': '192.168.99.100'})
for event in events:
	producer.produce('test', json.dumps(event))
producer.flush()