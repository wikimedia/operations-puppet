#!/usr/bin/env python

import argparse
from elasticsearch import Elasticsearch


class ElasticTool:
    def __init__(self, desc):
        self.parser = argparse.ArgumentParser(description=desc)
        self.parser.add_argument("--server", metavar='S', type=str,
                                 default="localhost",
                                 help="Server to work on, default localhost")

    def health(self, server):
        es = Elasticsearch(server)
        return es.cluster.health()["status"]
