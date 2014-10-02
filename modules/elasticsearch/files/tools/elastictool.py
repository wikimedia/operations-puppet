#!/usr/bin/env python

import argparse
import sys
from elasticsearch import Elasticsearch
from elasticsearch import ConnectionError


class ElasticTool:
    def __init__(self, desc):
        self.parser = argparse.ArgumentParser(description=desc)
        self.parser.add_argument("--server", metavar='S', type=str,
                                 default="localhost",
                                 help="Server to work on, default localhost")

    def run(self):
        self.args = self.parser.parse_args()
        self.server = self.args.server
        # Catch the most common exception in one place here
        try:
            self.execute()
        except ConnectionError:
            print "Unable to connect to server: " + self.server
            sys.exit(1)

    def execute(self):
        raise NotImplementedError("Please implement this method")

    def health(self):
        es = Elasticsearch(self.server)
        return es.cluster.health()["status"]

    def set_replication_state(self, status):
        es = Elasticsearch(self.server)
        res = es.cluster.put_settings(
            body={
                # custom analyzer for analyzing file paths
                "transient": {
                    "cluster.routing.allocation.enable": status
                }
            }
        )
        if res["acknowledged"]:
            return True
        else:
            return False
