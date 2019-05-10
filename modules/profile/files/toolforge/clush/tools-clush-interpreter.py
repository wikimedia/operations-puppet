#!/usr/bin/python
import argparse

import yaml

parser = argparse.ArgumentParser()
parser.add_argument(
    "--hostgroups", help="Path to YAML file with hostgroup information", required=True
)
subparsers = parser.add_subparsers(dest="action")

parser_map = subparsers.add_parser("map", help="Print list of hosts in a hostgroup")
parser_map.add_argument("group", help="Name of group whose instances should be printed")

parser_list = subparsers.add_parser("list", help="List all hostgroups")
args = parser.parse_args()

with open(args.hostgroups) as f:
    groups = yaml.safe_load(f)
    if args.action == "map":
        print("\n".join(groups[args.group]))
    if args.action == "list":
        print("\n".join(groups.keys()))
