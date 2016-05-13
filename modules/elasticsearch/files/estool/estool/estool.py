#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import division, print_function, absolute_import

import argparse
import sys
import logging
import argparse
import ipaddr
import os
import logging
import re
import subprocess
import sys
import time

from elasticsearch import TransportError
from subprocess import CalledProcessError
from estool import __version__

__author__ = "Guillaume Lederrey"
__copyright__ = "Guillaume Lederrey"
__license__ = "none"

_logger = logging.getLogger(__name__)


# How many times to try re-enabling allocation
REPLICATION_ENABLE_ATTEMPTS = 10


# We pipe things here....
DEV_NULL = open(os.devnull, 'w')

# Lets use a basic logging configuration so the Elasticsearch client doesn't
# complain. We go with ERROR here so curl doesn't log warnings when it can't
# connect to Elasticsearch. We already catch the exceptions for that and
# handle them.
logging.basicConfig(level=logging.ERROR)


class EsTool(object):
    def __init__(self, elastic):
        self._elastic = elastic

    def ban_node(self, node):
        if node == "":
            print("No node provided")
            return os.EX_UNAVAILABLE

        node_type = get_node_type(node)
        banned = self._elastic.get_banned_nodes(node_type)
        if node in banned:
            print(node + " already banned from allocation, nothing to do")
            return os.EX_OK

        banned.append(node)
        if self._elastic.set_banned_nodes(banned, node_type):
            print("Banned " + node)
            return os.EX_OK
        else:
            print("Failed to ban " + node)
            return os.EX_UNAVAILABLE

    def health(self):
        health = self._elastic.cluster_health()
        print(health)
        if health != "green":
            return os.EX_UNAVAILABLE
        else:
            return os.EX_OK

    def restart_fast(self, server="localhost", while_down=lambda: 0):
        # Sanity checks
        if os.getuid() != 0:
            print("Must be run as root")
            return os.EX_UNAVAILABLE
        if server != "localhost":
            print("Must be run against localhost only")
            return os.EX_UNAVAILABLE

        # Disable replication so we can make recovery easier
        print("Disabling non-primary replication...")
        if not self._elastic.set_allocation_state("primaries"):
            print("failed!")
            return os.EX_UNAVAILABLE
        print("ok\n", end='')

        print("Stopping elasticsearch...")
        try:
            process_args = ["service", "elasticsearch", "stop"]
            subprocess.check_call(process_args, stdout=DEV_NULL)
        except CalledProcessError:
            print("failed! Elasticserch is probably not stopped but you will ", end='')
            print("need to enable replication again with ", end='')
            print("`es-tool start-replication`")
            return os.EX_UNAVAILABLE
        print("ok")

        print("Double checking elasticsearch is stopped...")
        end = time.time()
        contains_re = re.compile("java.*elasticsearch-\\d+\\.\\d+\\.\\d\\.jar")
        while True:
            try:
                ps = subprocess.Popen(["ps", "auxww"], stdout=subprocess.PIPE)
                ps_out, _ = ps.communicate()
                if contains_re.search(ps_out):
                    if time.time() > end + 240:
                        print("betrayal! Elasticserch never stopped! You will ", end='')
                        print("need to enable replication again with ", end='')
                        print("`es-tool start-replication`")
                        return os.EX_UNAVAILABLE
                    else:
                        print(".", end='')
                        time.sleep(1)
                    continue
                break
            except CalledProcessError:
                print("failed to complete the check! Elasticsearch might be ", end='')
                print("stopped or stopping so so you ", end='')
                print("will have to start it again with `sudo service ", end='')
                print("elasticsearch start and then reenable replication ", end='')
                print("with `es-tool start-replication`")
                return os.EX_UNAVAILABLE
        print("ok")

        error = while_down()
        if error:
            return error

        print("Starting elasticsearch...")
        try:
            process_args = ["service", "elasticsearch", "start"]
            subprocess.check_call(process_args, stdout=DEV_NULL)
        except CalledProcessError:
            print("failed! Elasticsearch is probably still stopped so you ", end='')
            print("will have to start it again with `sudo service ", end='')
            print("elasticsearch start and then reenable replication ", end='')
            print("with `es-tool start-replication`")
            return os.EX_UNAVAILABLE
        print("ok")

        # Wait for it to come back alive
        print("Waiting for Elasticsearch...")
        while True:
            try:
                if self._elastic.cluster_health():
                    print("ok")
                    break
            except:
                pass
            print(".", end='')
            time.sleep(1)

        # Let things settle a bit
        time.sleep(3)

        # Turn replication back on so things will recover fully
        print("Enabling all replication...")

        if not self._elastic.set_allocation_state("all"):
            print("failed! -- You will still need to enable replication ", end='')
            print("again with `es-tool start-replication`")
            return os.EX_UNAVAILABLE
        else:
            print("ok")

        # Wait a bit
        time.sleep(5)
        return self.wait_for_green()

    def restart_if_oldest(self):
        # check if we are oldest node in cluster
        if not self._elastic.is_longest_running_node_in_cluster():
            print("Local node is not the longest running, not restarting it.")
            return os.EX_OK

        # make sure cluster is green and staying green
        try:
            self.wait_for_green_duration(5 * 60, 15 * 60)
        except TimeoutException:
            print("Cluster does not seem to be stable")
            return os.EX_UNAVAILABLE

        # restart
        # return es_restart_fast()
        print("restarting")

    def start_replication(self):
        if self._elastic.set_allocation_state("all"):
            print("All replication enabled")
            return os.EX_OK
        else:
            print("Failed to set replication state")
            return os.EX_UNAVAILABLE

    def stop_replication(self):
        if self._elastic.set_allocation_state("primaries"):
            print("Non-primary replication disabled")
            return os.EX_OK
        else:
            print("Failed to set replication state")
            return os.EX_UNAVAILABLE

    def eupgrade_fast(self):
        def upgrade_commands():
            print("Updating apt...")
            try:
                subprocess.check_call(["apt-get", "update"], stdout=DEV_NULL)
            except CalledProcessError:
                print("failed! Elasticsearch is still stopped so you ", end='')
                print("will have to start it again with `sudo service", end='')
                print("elasticsearch start and then reenable replication", end='')
                print("with `es-tool start-replication`")
                return os.EX_UNAVAILABLE
            print("ok")

            print("Installing Elasticsearch...")
            try:
                process_args = [
                    "apt-get",
                    "-o", 'Dpkg::Options::="--force-confdef"',
                    "-o", 'Dpkg::Options::="--force-confold"',
                    "install", "elasticsearch"]
                subprocess.check_call(process_args, stdout=DEV_NULL)
            except CalledProcessError:
                print("failed! Elasticsearch is still stopped so you", end='')
                print("will have to start it again with `sudo service", end='')
                print("elasticsearch start and then reenable replication")
                print("with `es-tool start-replication`")
                return os.EX_UNAVAILABLE
            print("ok")

        self.restart_fast(upgrade_commands)

    def unban_node(self, node):
        if node == "":
            print("No node provided")
            return os.EX_UNAVAILABLE

        node_type = get_node_type(node)

        banned = self._elastic.get_banned_nodes(node_type)
        if node not in banned:
            print(node + " not banned from allocation, nothing to do")
            return os.EX_OK

        banned.remove(node)
        if self._elastic.set_banned_nodes(banned, node_type):
            print("Unbanned " + node)
            return os.EX_OK
        else:
            print("Failed to unban " + node)
            return os.EX_UNAVAILABLE

    def wait_for_green(self):
        print("Waiting for green (you can ctrl+c here if you have to)...\n")
        while not self._elastic.is_cluster_healthy():
            try:
                print('\n'.join(self._elastic.cluster_status(
                    columns=(
                        'status',
                        'initializing_shards',
                        'relocating_shards',
                        'unassigned_shards'))))
            except:
                print("Cannot print cluster status\n")
            time.sleep(60)
        print("ok")
        return os.EX_OK

    def wait_for_green_duration(self, duration_in_seconds, max_in_seconds):
        """Check that cluster stay green for some time.

        This will block and return once the cluster has stayed green for the
        required amount of time. If cluster goes red while we are waiting, the
        timer is reset and we wait again.

        If max_in_second is reached, we throw an exception, indicating that the
        cluster did not stay green long enough.
        """
        cluster_is_green = False
        green_since = time.time()
        start_time = time.time()
        while True:
            now = time.time()
            print("now")
            print(now)
            if self._elastic.is_cluster_healthy():
                print("healthy")
                print(green_since)
                if not cluster_is_green:
                    cluster_is_green = True
                    green_since = now
                if cluster_is_green and (now - green_since > duration_in_seconds):
                    return
            else:
                print("not healthy")
                cluster_is_green = False
            if now - start_time > max_in_seconds:
                print("timeout")
                raise TimeoutException()
            print("sleeping")
            time.sleep(5)


class TimeoutException(Exception):
    pass

# Helper functions go here


def get_node_type(node):
    try:
        ipaddr.IPv4Address(node)
        return "_ip"
    except ipaddr.AddressValueError:
        try:
            ipaddr.IPv6Address(node)
            return "_ip"
        except ipaddr.AddressValueError:
            return "_host"


# And register them here

commands = {
    "ban-node": es_ban_node,
    "health": es_health,
    "restart-fast": (lambda: es_restart_fast(lambda: 0)),
    "restart-if-oldest": es_restart_if_oldest,
    "start-replication": es_start_replication,
    "status": lambda: '\n'.join(cluster_status()),
    "stop-replication": es_stop_replication,
    "unban-node": es_unban_node,
    "upgrade-fast": es_upgrade_fast,
    "wait-for-green": es_wait_for_green,
}


def main():
    parser = argparse.ArgumentParser(
        description="Tool for Elasticsearch cluster maintenance")
    parser.add_argument("command", metavar='CMD', type=str,
                        choices=commands.keys(),
                        help="Subcommand, one of: " + ",".join(commands))
    parser.add_argument("node", metavar='NODE', type=str, nargs="?", default="",
                        help="IP address or hostname, used by (un)ban-node")
    parser.add_argument("--server", metavar='S', type=str, default="localhost",
                        help="Server to work on, default localhost")
    parser.add_argument("--timeout", metavar='T', type=int, default=10,
                        help="Timeout (in second), default 10")
    parser.add_argument("--master_timeout", metavar='MT', type=int, default=30,
                        help="Timeout to connect to the master node (in second), "
                             "default 30")
    args = parser.parse_args()

    try:
        sys.exit(commands[args.command]())
    except TransportError as te:
        print(te)
        sys.exit(os.EX_UNAVAILABLE)

def run():
    main(sys.argv[1:])


if __name__ == "__main__":
    run()
