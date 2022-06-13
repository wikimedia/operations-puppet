#!/usr/bin/python
# SPDX-License-Identifier: BSD-2-Clause
# -*- coding: utf-8-*-

# NOTE: This file is managed by puppet.
# This script was copied from https://github.com/williamsjj/kafka_health

####################################################################
# FILENAME: check_kafka_consumer_group.py
# PROJECT: kafka_health
# DESCRIPTION: Nagios check for monitoring Kafka consumer groups
#              via a Burrow server.
#
####################################################################
# (C)2016 DigiTar Inc., All Rights Reserved
# Licensed under the BSD license.
####################################################################

from argparse import ArgumentParser
import sys
import urllib2
import time
import json

NAGIOS_CRITICAL = 2
NAGIOS_WARNING = 1
NAGIOS_OK = 0
NAGIOS_UNKNOWN = -1

STATUS_MSG_PREFIX = {
    NAGIOS_CRITICAL: "CRITICAL",
    NAGIOS_WARNING: "WARNING",
    NAGIOS_OK: "OK",
    NAGIOS_UNKNOWN: "UNKNOWN"
}

parser = ArgumentParser(
    description="Monitor a Kafka consumer group using Burrow. "
                "(https://github.com/linkedin/Burrow)"
)
parser.add_argument("--base-url", dest="base_url", required=True,
                    help="Base URL of Burrow monitoring server without path.")
parser.add_argument("--kafka-cluster", dest="kafka_cluster",
                    help="Kafka cluster name (as defined in Burrow)",
                    required=True)
parser.add_argument("--consumer-group", dest="consumer_group",
                    help="Kafka consumer group to monitor.",
                    required=True)
parser.add_argument("--critical-lag", dest="critical_lag",
                    type=int, default=1000,
                    help="Critical threshold for consumer group lag.")


class Status (object):

    def __init__(self, status):
        self.status = status
        self.status_msg = u""

    def updateStatus(self,  new_status, msg=None):
        if new_status > self.status:
            self.status = new_status
        if msg:
            self.status_msg = u"%s %s" % (self.status_msg, msg)

        return


if __name__ == "__main__":
    args = parser.parse_args()

    # Build Request
    if args.base_url[-1] == "/":
        args.base_url = args.base_url[:-1]
    req = urllib2.Request(
        url="%(base_url)s/v2/kafka/%(kafka_cluster)s/consumer/%(consumer_group)s/status" %
            args.__dict__
    )

    # Run Check
    try:
        start = time.time()
        res = urllib2.urlopen(req)
        end = time.time()
    except urllib2.HTTPError, e:
        print(
            "CRITICAL: Server %s returned error %d - %s (%s)" %
            (args.base_url, e.code, e.msg, e.read())
        )
        sys.exit(NAGIOS_CRITICAL)
    except urllib2.URLError, e:
        print("CRITICAL: Problem connecting to %s - %s" % (args.base_url, e.reason))
        sys.exit(NAGIOS_CRITICAL)
    except Exception, e:
        print("CRITICAL: Unknown error occurred. %s" % str(e))
        sys.exit(NAGIOS_CRITICAL)

    try:
        output = res.read()
        json_output = json.loads(output)
    except Exception, e:
        print(
            "CRITICAL: Error decoding API result to JSON - %s (API result: %s)" % (str(e), output)
        )
        sys.exit(NAGIOS_CRITICAL)

    if json_output["error"]:
        print("CRITICAL: %s" % json_output["message"])
        sys.exit(NAGIOS_CRITICAL)

    # Set general check status
    status_result = Status(NAGIOS_OK)
    if json_output["status"]["status"] == "NOTFOUND":
        status_result.updateStatus(
            NAGIOS_WARNING, "%s consumer group not found in this cluster." % args.consumer_group
        )
    elif json_output["status"]["status"] == "WARN":
        status_result.updateStatus(NAGIOS_WARNING, "Group or partition is in a warning state.")
    elif json_output["status"]["status"] == "ERR":
        # If maxlag is set, then choose critical.
        if json_output["status"]["maxlag"] is not None:
            status = NAGIOS_CRITICAL
        # else if there are any partition statuses present other than STOP,
        # then choose warning.
        elif (
            [p['status'] for p in json_output['status']['partitions']].count("STOP") !=
            len(json_output['status']['partitions'])
        ):
            status = NAGIOS_WARNING
        # Else we are in an 'error' state, but everything is really fine.
        # Stopped partitions with no lag just means there haven't been
        # recent messages in these partitions.
        else:
            status = NAGIOS_OK

        status_result.updateStatus(status, "Group is in an error state.")
    elif json_output["status"]["status"] == "STOP":
        status_result.updateStatus(NAGIOS_WARNING, "A partition has stopped.")
    elif json_output["status"]["status"] == "STALL":
        status_result.updateStatus(NAGIOS_CRITICAL, "A partition has stalled.")
    elif json_output["status"]["status"] != "OK":
        status_result.updateStatus(
            NAGIOS_WARNING, "Unexpected status value: %s" % json_output["status"]["status"]
        )

    # Parse maxlag info
    max_lag_detail = ""
    if json_output["status"]["maxlag"]:
        max_lag = json_output["status"]["maxlag"]
        max_lag_detail = "Worst Lag: %s/p%d - lag:%d offset:%d" % (
            max_lag["topic"],
            max_lag["partition"],
            max_lag["end"]["lag"],
            max_lag["end"]["offset"]
        )
        if max_lag["end"]["lag"] >= args.critical_lag:
            status_result.updateStatus(NAGIOS_CRITICAL)

    status_result.updateStatus(NAGIOS_UNKNOWN, max_lag_detail)

    # Compile problem partition stats
    problem_topic_partitions = {}
    for part in json_output["status"]["partitions"]:
        if part["status"] in ["WARN", "STOP", "STALL"]:
            if part["topic"] not in problem_topic_partitions:
                problem_topic_partitions[part["topic"]] = {"WARN": [], "STOP": [], "STALL": []}
            problem_topic_partitions[part["topic"]][part["status"]].append(part["partition"])

    problem_partition_detail = ""
    for topic in problem_topic_partitions.keys():
        problem_partition_detail = "%s(%s WARN:%d STOP:%d STAL:%d) " % (
            problem_partition_detail,
            topic,
            len(problem_topic_partitions[topic]["WARN"]),
            len(problem_topic_partitions[topic]["STOP"]),
            len(problem_topic_partitions[topic]["STALL"])
        )

    if problem_partition_detail:
        status_result.updateStatus(NAGIOS_UNKNOWN, "|"+problem_partition_detail)

    # Return status
    print("%s: %s" % (STATUS_MSG_PREFIX[status_result.status], status_result.status_msg))
    sys.exit(status_result.status)
