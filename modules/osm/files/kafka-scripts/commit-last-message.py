#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import argparse
from kafka import KafkaConsumer


def seek_partitions_end(topic, broker, group_id):
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=[broker],
        group_id=group_id,
    )
    consumer.poll()
    consumer.seek_to_end()
    consumer.poll()
    consumer.commit()
    consumer.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Kafka commit last message")
    parser.add_argument("--topic", type=str, help="Kafka topic")
    parser.add_argument("--broker", type=str, help="Kafka broker")
    parser.add_argument("--group-id", type=str, help="Kafka group ID")
    args = parser.parse_args()

    print(args)
    seek_partitions_end(
        args.topic,
        args.broker,
        args.group_id,
    )
