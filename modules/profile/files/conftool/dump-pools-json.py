#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) Giuseppe Lavagetto, Wikimedia Foundation 2023
"""Script to dump the conftool pools to a json file."""

import argparse
import json
import pathlib
import re

from typing import Optional

from conftool.cli.tool import ToolCliBase


class DumpJson(ToolCliBase):
    """Dump the nodes to json"""

    def __init__(self, args: argparse.Namespace):
        super().__init__(args)
        self.output_file: Optional[pathlib.Path] = None
        if args.output:
            self.output_file = pathlib.Path(args.output)

    def announce(self):
        """Do not send messages to IRC."""

    def _run_action(self):
        pass

    def run(self):
        """Dump the pool status to disc as a json tree"""
        self.setup()
        result = {}
        selector = {"name": re.compile(".+")}
        for node in self.entity.query(selector):
            host = node.name
            dc = node.tags["dc"]
            cluster = node.tags["cluster"]
            service = node.tags["service"]

            payload = {service: {"weight": node.weight, "pooled": node.pooled == "yes"}}
            # Insert the payload at the right place in the hierarchy.
            # This code deliberately avoids using nested defaultdicts so that it's
            # easier to understand and debug.
            if dc not in result:
                result[dc] = {cluster: {host: payload}}
            elif cluster not in result[dc]:
                result[dc][cluster] = {host: payload}
            elif host not in result[dc][cluster]:
                result[dc][cluster][host] = payload
            else:
                result[dc][cluster][host][service] = payload[service]
        if self.output_file is None:
            print(json.dumps(result))
        else:
            self.output_file.write_text(json.dumps(result), encoding="utf-8")


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="dump as json")
    parser.add_argument(
        "--config", help="Conftool config file", default="/etc/conftool/config.yaml"
    )
    parser.add_argument("--debug", action="store_true", default=False, help="print debug info")
    parser.add_argument(
        "--output",
        default="",
        help="Optional output file",
    )
    args = parser.parse_args()
    # Inject parameters needed by ToolCliBase we're not allowing to modify.
    args.object_type = "node"
    args.schema = "/etc/conftool/schema.yaml"
    return args


def main():
    """Dump all nodes information."""
    args = parse_args()
    dumper = DumpJson(args)
    dumper.run()


main()
