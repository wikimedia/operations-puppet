#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import signal
from kafka import KafkaConsumer


def close_kafka(signal, frame):
    raise SystemExit(0)


signal.signal(signal.SIGINT, close_kafka)
signal.signal(signal.SIGTERM, close_kafka)


def consume_all(topic, broker, group_id, commit, offset):
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=[broker],
        enable_auto_commit=commit,
        auto_offset_reset=offset,
        group_id=group_id,
    )

    try:
        for msg in consumer:
            print(msg)
    except SystemExit:
        if commit:
            consumer.commit()
        consumer.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Kafka messages consumer")
    parser.add_argument("--topic", type=str, help="Kafka topic")
    parser.add_argument("--broker", type=str, help="Kafka broker")
    parser.add_argument("--group-id", type=str, help="Kafka group ID")
    parser.add_argument("--offset", type=str, help="Kafka offset")
    parser.add_argument(
        "--commit",
        help="Enable offset commits",
        dest="commit",
        action="store_true",
    )
    parser.add_argument(
        "--no-commit",
        help="Disable offset commits",
        dest="commit",
        action="store_false",
    )
    parser.set_defaults(offset="earliest")
    parser.set_defaults(commit=False)
    args = parser.parse_args()

    print(args)

    consume_all(args.topic, args.broker, args.group_id, args.commit, args.offset)
