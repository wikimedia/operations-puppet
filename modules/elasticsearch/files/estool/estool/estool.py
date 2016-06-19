#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import division, print_function, absolute_import

import argparse
from logging.config import dictConfig

import ipaddr
import os
import logging
import re
import subprocess
import sys
import time

from elasticsearch import TransportError
from subprocess import CalledProcessError
from estool.elastic import Elastic, ElasticException
from elasticsearch import Elasticsearch

__author__ = "Guillaume Lederrey"
__copyright__ = "Guillaume Lederrey"
__license__ = "none"


# We pipe things here....
DEV_NULL = open(os.devnull, 'w')

# Lets use a basic logging configuration so the Elasticsearch client doesn't
# complain. We go with ERROR here so curl doesn't log warnings when it can't
# connect to Elasticsearch. We already catch the exceptions for that and
# handle them.
# logging.basicConfig(level=logging.WARN)

logging_config = dict(
    version=1,
    formatters={
        'f': {'format': '%(asctime)s %(name)-12s %(levelname)-8s %(message)s'}
    },
    handlers={
        'h': {
            'class': 'logging.StreamHandler',
            'formatter': 'f',
            'level': logging.DEBUG
        }
    },
    root={
        'handlers': ['h'],
        'level': logging.WARN
    },
    logger_estool={'level': logging.INFO},
    logger_elasticsearch={'level': logging.ERROR},
    logger_urllib3={'level': logging.ERROR}
)
dictConfig(logging_config)

logger = logging.getLogger(__name__)


class EsToolException(Exception):
    pass


class ClusterNotGreenException(EsToolException):
    pass


class TimeoutException(EsToolException):
    pass


class EsTool(object):
    def __init__(self, elastic):
        self.logger = logging.getLogger('estool.EsTool')
        self.elastic = elastic

    def ban_node(self, node):
        if node == "":
            raise EsToolException("No node provided")

        node_type = get_node_type(node)
        banned = self.elastic.get_banned_nodes(node_type)
        if node in banned:
            self.logger.info("%s already banned from allocation, nothing to do", node)
            return

        banned.append(node)
        if self.elastic.set_banned_nodes(banned, node_type):
            self.logger.info("Banned " + node)
            return
        else:
            raise EsToolException("Failed to ban %s", node)

    def health(self):
        health = self.elastic.cluster_health()
        self.logger.info("Cluster health: %s", health)
        if health != "green":
            raise ClusterNotGreenException

    def restart_fast(self, server="localhost", while_down=lambda: 0):
        # Sanity checks
        if os.getuid() != 0:
            raise EsToolException("Must be run as root")
        if server != "localhost":
            raise EsToolException("Must be run against localhost only")

        # Disable replication so we can make recovery easier
        self.stop_replication()

        self.logger.info("Stopping elasticsearch...")
        try:
            process_args = ["service", "elasticsearch", "stop"]
            subprocess.check_call(process_args, stdout=DEV_NULL)
        except CalledProcessError:
            raise EsToolException("Failed! Elasticsearch is probably not stopped but you will "
                                  "need to enable replication again with "
                                  "`es-tool start-replication`")
        self.logger.info("Elasticsearch stopped.")

        self.logger.info("Double checking elasticsearch is stopped...")
        end = time.time()
        contains_re = re.compile("java.*elasticsearch-\\d+\\.\\d+\\.\\d\\.jar")
        while True:
            try:
                ps = subprocess.Popen(["ps", "auxww"], stdout=subprocess.PIPE)
                ps_out, _ = ps.communicate()
                if contains_re.search(ps_out):
                    if time.time() > end + 240:
                        raise EsToolException("betrayal! Elasticserch never stopped! You will "
                                              "need to enable replication again with "
                                              "`es-tool start-replication`")
                    else:
                        self.logger.info(".")
                        time.sleep(1)
                    continue
                break
            except CalledProcessError:
                raise EsToolException("failed to complete the check! Elasticsearch might be "
                                      "stopped or stopping so so you "
                                      "will have to start it again with `sudo service "
                                      "elasticsearch start and then reenable replication "
                                      "with `es-tool start-replication`")
        self.logger.info("Double checked that Elasticsearch is stopped.")

        while_down()

        self.logger.info("Starting elasticsearch...")
        try:
            process_args = ["service", "elasticsearch", "start"]
            subprocess.check_call(process_args, stdout=DEV_NULL)
        except CalledProcessError:
            raise EsToolException("failed! Elasticsearch is probably still stopped so you "
                                  "will have to start it again with `sudo service "
                                  "elasticsearch start and then reenable replication "
                                  "with `es-tool start-replication`")
        self.logger.info("Elasticsearch started.")

        self.logger.info("Waiting for Elasticsearch...")
        while True:
            try:
                if self.elastic.cluster_health():
                    self.logger.info("Elasticsearch running.")
                    break
            except:
                pass
            self.logger.info(".")
            time.sleep(1)

        # Let things settle a bit
        time.sleep(3)

        # Turn replication back on so things will recover fully
        try:
            self.start_replication()
        except EsToolException as ete:
            raise EsToolException(ete.message + " -- You will still need to enable replication "
                                  "again with `es-tool start-replication`")

        self.wait_for_green()

    def restart_if_oldest(self):
        # check if we are oldest node in cluster
        if not self.elastic.is_longest_running_node_in_cluster():
            self.logger.info("Local node is not the longest running, not restarting it.")
            return

        # make sure cluster is green and staying green
        try:
            self.wait_for_green_duration(5 * 60, 15 * 60)
        except TimeoutException:
            raise EsToolException("Cluster does not seem to be stable, aborting restart.")

        self.logger.debug("restarting...")
        # restart
        # return es_restart_fast()

    def start_replication(self):
        if self.elastic.set_allocation_state("all"):
            self.logger.info("All replication enabled")
        else:
            raise EsToolException("Failed enable replication")

    def stop_replication(self):
        self.logger.info("Disabling non-primary replication...")
        try:
            self.elastic.set_allocation_state("primaries")
            self.logger.info("Non-primary replication disabled.")
        except ElasticException:
            raise EsToolException("Failed to disable non-primary replication.")

    def upgrade_fast(self):
        def upgrade_commands():
            upgrade_logger = logging.getLogger('estool.upgrade_command')
            upgrade_logger.info("Updating apt...")
            try:
                subprocess.check_call(["apt-get", "update"], stdout=DEV_NULL)
            except CalledProcessError:
                raise EsToolException("failed! Elasticsearch is still stopped so you "
                                      "will have to start it again with `sudo service"
                                      "elasticsearch start and then reenable replication"
                                      "with `es-tool start-replication`")
            upgrade_logger.info("Apt updated.")

            upgrade_logger.info("Installing Elasticsearch...")
            try:
                process_args = [
                    "apt-get",
                    "-o", 'Dpkg::Options::="--force-confdef"',
                    "-o", 'Dpkg::Options::="--force-confold"',
                    "install", "elasticsearch"]
                subprocess.check_call(process_args, stdout=DEV_NULL)
            except CalledProcessError:
                raise EsToolException("failed! Elasticsearch is still stopped so you"
                                      "will have to start it again with `sudo service"
                                      "elasticsearch start and then reenable replication"
                                      "with `es-tool start-replication`")
            upgrade_logger.info("Elasticsearch installed.")

        self.restart_fast(upgrade_commands)

    def unban_node(self, node):
        if node == "":
            raise EsToolException("No node provided")

        node_type = get_node_type(node)

        banned = self.elastic.get_banned_nodes(node_type)
        if node not in banned:
            self.logger.info("%s not banned from allocation, nothing to do", node)
            return

        banned.remove(node)
        try:
            self.elastic.set_banned_nodes(banned, node_type)
            self.logger.info("Unbanned %s", node)
        except ElasticException:
            raise EsToolException("Failed to unban " + node)

    def wait_for_green(self):
        self.logger.info("Waiting for green (you can ctrl+c here if you have to)...")
        while not self.elastic.is_cluster_healthy():
            try:
                self.logger.info('\n'.join(self.elastic.cluster_status(
                    columns=(
                        'status',
                        'initializing_shards',
                        'relocating_shards',
                        'unassigned_shards'))))
            except:
                self.logger.warn("Cannot print cluster status")
            time.sleep(10)
        self.logger.info("Cluster is green.")

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
            self.logger.debug("now: %d", now)
            if self.elastic.is_cluster_healthy():
                self.logger.debug("healthy since: %d", green_since)
                if not cluster_is_green:
                    cluster_is_green = True
                    green_since = now
                if cluster_is_green and (now - green_since > duration_in_seconds):
                    return
            else:
                self.logger.debug("not healthy")
                cluster_is_green = False
            if now - start_time > max_in_seconds:
                raise TimeoutException()
            self.logger.debug("sleeping")
            time.sleep(5)


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


def main(args):
    # list of methods on EsTool that can be used as commands
    commands = [
        "ban-node",
        "health",
        "restart-fast",
        "restart-if-oldest",
        "start-replication",
        "status",
        "stop-replication",
        "unban-node",
        "upgrade-fast",
        "wait-for-green",
    ]
    parser = argparse.ArgumentParser(
        description="Tool for Elasticsearch cluster maintenance")
    parser.add_argument("command", metavar='CMD', type=str,
                        choices=commands,
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
    args = parser.parse_args(args)

    try:
        elasticsearch = Elasticsearch(args.server)
        elastic = Elastic(elasticsearch, timeout=args.timeout, master_timeout=args.master_timeout)
        estool = EsTool(elastic)

        command = getattr(estool, args.command.replace('-', '_'))
        command()
        sys.exit(os.EX_OK)

    except ClusterNotGreenException:
        sys.exit(os.EX_UNAVAILABLE)

    except (EsToolException, TransportError) as ex:
        logger.error(ex.message)
        logger.debug(ex)
        sys.exit(os.EX_UNAVAILABLE)


def run():
    main(sys.argv[1:])


if __name__ == "__main__":
    run()
