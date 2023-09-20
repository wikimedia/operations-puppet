#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# Maintained by Puppet

"""
Checks if all partitions assigned to the current broker are in sync.

If this is the case, the script will exit with a status code
of 0. If not, it will exit with a status code of 1.
"""

import configparser
import json
import sys
from pathlib import Path

from kazoo.client import KazooClient
from kazoo.exceptions import NoNodeError


class ExtendedKazooClient(KazooClient):
    """A wrapper around the base Zookeeper client easing access to the kafka partitions metadata."""

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop()

    def get_node(self, node_path):
        """Return the JSON-deserialized content of a Zookeeper znode.
        If the node is not found, raise a NoNodeError exception.
        """
        try:
            data, _ = self.get(node_path)
        except NoNodeError:
            raise
        else:
            if data:
                return json.loads(data)

    def topics(self):
        """Yield all topic names in the cluster"""
        for topic in self.get_children("/brokers/topics"):
            yield topic

    def topic(self, topic_name):
        """Return the content of the znode of a given topic"""
        return self.get_node(f"/brokers/topics/{topic_name}")

    def partition(self, topic, partition_id):
        """Return the content of the znode for a given topic/partition"""
        return self.get_node(f"/brokers/topics/{topic}/partitions/{partition_id}/state")

    def topic_partitions_config(self, topic):
        """Return the list of partitions and assigned brokers for a given topic"""
        return self.topic(topic)["partitions"]

    def broker_topic_partitions(self, broker_id):
        """Yield all topic/partitions assigned to the argument broker id"""
        for topic in self.topics():
            for partition, brokers in self.topic_partitions_config(topic).items():
                if int(broker_id) in brokers:
                    yield topic, int(partition)

    def broker_has_partition_in_sync(self, topic, partition_id, broker_id):
        """Return whether the topic/partition is in sync on the argument broker id"""
        partition_state = self.partition(topic, partition_id)
        return broker_id in partition_state["isr"]


def fail(message):
    print(message)
    sys.exit(1)


def load_properties(filepath):
    """Read the file passed as parameter as a properties file."""
    config = configparser.ConfigParser()
    config_text = f"[{configparser.DEFAULTSECT}]\n" + Path(filepath).read_text()
    config.read_string(config_text)
    return config[configparser.DEFAULTSECT]


def main():
    kafka_properties = load_properties("/etc/kafka/server.properties")
    broker_id = int(kafka_properties["broker.id"])
    zk_connect = kafka_properties["zookeeper.connect"]

    try:
        with ExtendedKazooClient(hosts=zk_connect) as zk:
            for topic, partition in zk.broker_topic_partitions(broker_id):
                if not zk.broker_has_partition_in_sync(topic, partition, broker_id):
                    fail(f"Broker {broker_id} is still catching up")
    except Exception as exc:
        fail(str(exc))


if __name__ == "__main__":
    main()
