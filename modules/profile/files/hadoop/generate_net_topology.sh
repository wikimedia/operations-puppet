#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

/usr/local/bin/hadoop-hdfs-net-topology.py --config /etc/hadoop/conf/net-topology.ini "$@"