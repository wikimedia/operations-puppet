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
import pprint

from elasticsearch import Elasticsearch, TransportError
from elasticsearch.exceptions import ConnectionError
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
# connect to Elasticsearch. We alreaady catch the exceptions for that and
# handle them.
logging.basicConfig(level=logging.ERROR)


class TimeoutException(Exception):
    pass

# Helper functions go here
def cluster_health():
    es = Elasticsearch(args.server)
    return es.cluster.health(master_timeout=args.master_timeout,
                             timeout=args.timeout)["status"]


def cluster_status(columns=None):
    es = Elasticsearch(args.server)
    cluster_health = es.cluster.health(master_timeout=args.master_timeout,
                                       timeout=args.timeout)
    if columns is None:
        columns = sorted(cluster_health)
    values = [cluster_health[x] for x in columns]

    column_fmt = ' '.join('{:>}' for x in columns)
    value_fmt = ' '.join('{:>%s}' % len(x) for x in columns)

    yield column_fmt.format(*columns)
    yield value_fmt.format(*values)


def set_setting(setting, value, settingtype="transient"):
    es = Elasticsearch(args.server)
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


def set_allocation_state(status):
    for attempt in range(REPLICATION_ENABLE_ATTEMPTS):
        try:
            if set_setting("cluster.routing.allocation.enable", status):
                return True
        except:
            time.sleep(3)
            print "failed! -- retrying (%d/%d)" % (attempt,
                                                   REPLICATION_ENABLE_ATTEMPTS)
    return False


def set_banned_nodes(nodelist, node_type):
    return set_setting("cluster.routing.allocation.exclude." + node_type,
                       ",".join(nodelist))


def get_banned_nodes(node_type):
    es = Elasticsearch(args.server)
    res = es.cluster.get_settings(master_timeout=args.master_timeout,
                                  timeout=args.timeout)
    try:
        bannedstr = res["transient"]["cluster"]["routing"]["allocation"][
            "exclude"][node_type]
        if bannedstr:
            return bannedstr.split(",")
    except KeyError:
        pass
    return []


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


# Add new command functions here
def es_ban_node():
    if args.node == "":
        print "No node provided"
        return os.EX_UNAVAILABLE

    node_type = get_node_type(args.node)

    banned = get_banned_nodes(node_type)
    if args.node in banned:
        print args.node + " already banned from allocation, nothing to do"
        return os.EX_OK

    banned.append(args.node)
    if set_banned_nodes(banned, node_type):
        print "Banned " + args.node
        return os.EX_OK
    else:
        print "Failed to ban " + args.node
        return os.EX_UNAVAILABLE


def es_health():
    health = cluster_health()
    print health
    if health != "green":
        return os.EX_UNAVAILABLE
    else:
        return os.EX_OK


def printu(string):
    sys.stdout.write(string)
    sys.stdout.flush()


def es_restart_fast(while_down):
    # Sanity checks
    if os.getuid() != 0:
        print "Must be run as root"
        return os.EX_UNAVAILABLE
    if args.server != "localhost":
        print "Must be run against localhost only"
        return os.EX_UNAVAILABLE

    # Disable replication so we can make recovery easier
    printu("Disabling non-primary replication...")
    if not set_allocation_state("primaries"):
        print "failed!"
        return os.EX_UNAVAILABLE
    printu("ok\n")

    printu("Stopping elasticsearch...")
    try:
        process_args = ["service", "elasticsearch", "stop"]
        subprocess.check_call(process_args, stdout=DEV_NULL)
    except CalledProcessError:
        print "failed! Elasticserch is probably not stopped but you will ",
        print "need to enable replication again with",
        print "`es-tool start-replication`"
        return os.EX_UNAVAILABLE
    printu("ok\n")

    printu("Double checking elasticsearch is stopped...")
    end = time.time()
    contains_re = re.compile("java.*elasticsearch-\\d+\\.\\d+\\.\\d\\.jar")
    while True:
        try:
            ps = subprocess.Popen(["ps", "auxww"], stdout=subprocess.PIPE)
            ps_out, _ = ps.communicate()
            if contains_re.search(ps_out):
                if time.time() > end + 240:
                    print "betrayal! Elasticserch never stopped! You will",
                    print "need to enable replication again with",
                    print "`es-tool start-replication`"
                    return os.EX_UNAVAILABLE
                else:
                    printu(".")
                    time.sleep(1)
                continue
            break
        except CalledProcessError:
            print "failed to complete the check! Elasticsearch might be",
            print "stopped or stopping so so you",
            print "will have to start it again with `sudo service",
            print "elasticsearch start and then reenable replication",
            print "with `es-tool start-replication`"

            return os.EX_UNAVAILABLE
    printu("ok\n")

    error = while_down()
    if error:
        return error

    printu("Starting elasticsearch...")
    try:
        process_args = ["service", "elasticsearch", "start"]
        subprocess.check_call(process_args, stdout=DEV_NULL)
    except CalledProcessError:
        print "failed! Elasticsearch is probably still stopped so you",
        print "will have to start it again with `sudo service",
        print "elasticsearch start and then reenable replication",
        print "with `es-tool start-replication`"
        return os.EX_UNAVAILABLE
    printu("ok\n")

    # Wait for it to come back alive
    printu("Waiting for Elasticsearch...")
    while True:
        try:
            if cluster_health():
                printu("ok\n")
                break
        except:
            pass
        printu(".")
        time.sleep(1)

    # Let things settle a bit
    time.sleep(3)

    # Turn replication back on so things will recover fully
    printu("Enabling all replication...")

    if not set_allocation_state("all"):
        print "failed! -- You will still need to enable replication",
        print "again with `es-tool start-replication`"
        return os.EX_UNAVAILABLE
    else:
        printu("ok\n")

    # Wait a bit
    time.sleep(5)
    es_wait_for_green()

    return os.EX_OK


def es_wait_for_green():
    print "Waiting for green (you can ctrl+c here if you have to)...\n"
    while not is_cluster_healthy():
        try:
            print '\n'.join(cluster_status(columns=('status',
                                                    'initializing_shards',
                                                    'relocating_shards',
                                                    'unassigned_shards')))
        except:
            printu("Cannot print cluster status\n")
        time.sleep(60)
    print "ok"


def is_cluster_healthy():
    try:
        return cluster_health() == "green"
    except:
        printu("Error while checking for cluster health\n")
        return False


def es_upgrade_fast():
    def upgrade_commands():
        printu("Updating apt...")
        try:
            subprocess.check_call(["apt-get", "update"], stdout=DEV_NULL)
        except CalledProcessError:
            print "failed! Elasticsearch is still stopped so you",
            print "will have to start it again with `sudo service",
            print "elasticsearch start and then reenable replication",
            print "with `es-tool start-replication`"
            return os.EX_UNAVAILABLE
        printu("ok\n")

        printu("Installing Elasticsearch...")
        try:
            process_args = [
                "apt-get",
                "-o", 'Dpkg::Options::="--force-confdef"',
                "-o", 'Dpkg::Options::="--force-confold"',
                "install", "elasticsearch"]
            subprocess.check_call(process_args, stdout=DEV_NULL)
        except CalledProcessError:
            print "failed! Elasticsearch is still stopped so you",
            print "will have to start it again with `sudo service",
            print "elasticsearch start and then reenable replication",
            print "with `es-tool start-replication`"
            return os.EX_UNAVAILABLE
        printu("ok\n")

    es_restart_fast(upgrade_commands)


def es_start_replication():
    if set_allocation_state("all"):
        print "All replication enabled"
        return os.EX_OK
    else:
        print "Failed to set replication state"
        return os.EX_UNAVAILABLE


def es_stop_replication():
    if set_allocation_state("primaries"):
        print "Non-primary replication disabled"
        return os.EX_OK
    else:
        print "Failed to set replication state"
        return os.EX_UNAVAILABLE


def es_unban_node():
    if args.node == "":
        print "No node provided"
        return os.EX_UNAVAILABLE

    node_type = get_node_type(args.node)

    banned = get_banned_nodes(node_type)
    if args.node not in banned:
        print args.node + " not banned from allocation, nothing to do"
        return os.EX_OK

    banned.remove(args.node)
    if set_banned_nodes(banned, node_type):
        print "Unbanned " + args.node
        return os.EX_OK
    else:
        print "Failed to unban " + args.node
        return os.EX_UNAVAILABLE


def longest_uptime(node_stats):
    max_uptime = 0
    for node_id, node in node_stats['nodes'].iteritems():
        max_uptime = max(max_uptime, node['jvm']['uptime_in_millis'])
    return max_uptime


def is_longest_running_node_in_cluster():
    es = Elasticsearch(args.server)
    node_stats = es.nodes.stats(metric='jvm')

    local_node_stats = es.nodes.stats(metric='jvm', node_id='_local')
    local_node_uptime = local_node_stats['nodes'][local_node_stats['nodes'].keys()[0]]['jvm']['uptime_in_millis']

    return local_node_uptime >= longest_uptime(node_stats)


def wait_for_green_duration(duration_in_seconds, maxInSeconds):
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
        print "now"
        print now
        if is_cluster_healthy():
            print "healthy"
            print green_since
            if not cluster_is_green:
                cluster_is_green = True
                green_since = now
            if (cluster_is_green) and (now - green_since > duration_in_seconds):
                return
        else:
            print "not healthy"
            cluster_is_green = False
        if now - start_time > maxInSeconds:
            print "timeout"
            raise TimeoutException()
        print "sleeping"
        time.sleep(5)


def es_restart_if_oldest():
    # check if we are oldest node in cluster
    if not is_longest_running_node_in_cluster():
        return os.EX_UNAVAILABLE

    # make sure cluster is green and staying green
    try:
        wait_for_green_duration(5 * 60, 15 * 60)
    except TimeoutException:
        printu("Cluster does not seem to be stable")
        return os.EX_UNAVAILABLE

    # restart
    # return es_restart_fast()
    printu("restarting")

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
