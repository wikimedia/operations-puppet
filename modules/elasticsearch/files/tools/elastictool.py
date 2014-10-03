#!/usr/bin/env python

import argparse
import socket
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

    def set_setting(self, setting, value, settingtype="transient"):
        es = Elasticsearch(self.server)
        res = es.cluster.put_settings(
            body={
                settingtype: {
                    setting: value
                }
            }
        )
        if res["acknowledged"]:
            return True
        else:
            return False

    def set_replication_state(self, status):
        return self.set_setting("cluster.routing.allocation.enable", status)

    def is_valid_ip(self, ip):
        try:
            socket.inet_aton(ip)
            return True
        except socket.error:
            return False

    def get_banned_ips(self):
        es = Elasticsearch(self.server)
        res = es.cluster.get_settings()
        try:
            if res["transient"]["cluster"]["routing"]["allocation"]["exclude"]["_ip"]:
                return res["transient"]["cluster"]["routing"]["allocation"]["exclude"]["_ip"].split(",")
        except KeyError:
            pass

        return []

    def set_banned_ips(self, iplist):
        return self.set_setting("cluster.routing.allocation.exclude._ip",
                                ",".join(iplist))
