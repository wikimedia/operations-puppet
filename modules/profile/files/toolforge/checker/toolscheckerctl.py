#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 Wikimedia Foundation All Rights Reserved.
import argparse
import os
import subprocess
import sys

UWSGI_CONF_DIR = "/etc/uwsgi/apps-enabled"

if os.geteuid() != 0:
    print("{} needs to be run as root".format(sys.argv[0]))
    sys.exit(1)

services = [
    "uwsgi-{}".format(os.path.splitext(fname)[0])
    for fname in os.listdir(UWSGI_CONF_DIR)
    if (fname.startswith("toolschecker_") and fname.endswith(".ini"))
]

argparser = argparse.ArgumentParser(
    description="Control toolschecker services")
argparser.add_argument(
    "action",
    choices=["start", "stop", "restart", "status"],
    help="""
    start: Start all toolschecker services
    stop: Stop all toolschecker services
    restart: Restart all toolschecker services
    status: Print status for all toolschecker services
    """
)
args = argparser.parse_args()

failures = []
for service in services:
    try:
        subprocess.check_call(
            ["systemctl", args.action, "--no-pager", "-l", service]
        )
    except subprocess.CalledProcessError:
        failures.append(service)

if failures:
    print("Errors seen from services:")
    for service in failures:
        print(" * {}".format(service))
    sys.exit(1)
