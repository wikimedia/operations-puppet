#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

"""
Purpose: a script to check the depool status of hosts running a given service

What This Does:

    1. Gets the state (pooled/depooled) of all conftool-accessible hosts
    2. Writes each's host state to the file referred to in the `-o` flag;
     a 1 indicates that the host is pooled, 0 indicates that it's depooled.
"""


from argparse import Namespace, ArgumentParser
from conftool.cli.tool import ToolCli
from prometheus_client import (
        CollectorRegistry,
        Gauge,
        write_to_textfile,
        generate_latest
)
import sys

tool_args = Namespace(config='/etc/conftool/config.yaml',
                      schema='/etc/conftool/schema.yaml',
                      object_type='node',
                      action='get',
                      quiet=True,
                      taglist='')
tc = ToolCli(tool_args)

parser = ArgumentParser(prog='svc-pool-status-exporter',
                        description='Gets the pool/depool status of all confd hosts\
                        and writes the results to a promfile')
parser.add_argument('-o', '--outfile')
args = parser.parse_args()
registry = CollectorRegistry()

# 1. get hosts' states
gauge = Gauge('svc_host_pooled_status',
              'indicates pool/depool status for a service',
              ['service', 'service_site', 'hostname', 'cluster'], registry=registry)
for node in tc.entity.query(dict()):
    svc_site = node.tags['dc']
    svc = node.tags['service']
    cluster = node.tags['cluster']
    if node.pooled == "yes":
        gauge.labels(svc, svc_site, node.name, cluster).set(float(1))
    else:
        gauge.labels(svc, svc_site, node.name, cluster).set(float(0))

# 2. print to stdout if no promfile, otherwise print to promfile
if args.outfile is None:
    print(generate_latest(registry).decode('utf-8'))
    sys.exit(0)

write_to_textfile(args.outfile, registry)
