#!/usr/bin/env python3

# (C) 2021 by Arturo Borrero Gonzalez <aborrero@wikimedia.org>

#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#

import argparse
import yaml
import pyinotify
import logging
import os
import sys
import re
import time
import subprocess

# netns file:
# /var/run/netns/qrouter-5712e22e-134a-40d3-a75a-1c9b441717ad

# configuration file format:
#
# - netns_regex: ^qrouter-.*
#   daemon_startup_actions:
#     - mycommand1
#     - mycommand2
#   inotify_actions:
#     - IN_CREATE:
#        - mycommand1
#        - mycommand2
#       IN_DELETE:
#        - mycommand3
#        - mycommand4
#


def read_yaml_file(file):
    try:
        with open(file, "r") as stream:
            try:
                return yaml.safe_load(stream)
            except yaml.YAMLError as e:
                logging.critical(e)
                exit(2)
    except FileNotFoundError as e:
        logging.critical(e)
        exit(2)


def validate_dict(dictionary, keys):
    if not isinstance(dictionary, dict):
        raise Exception(f"not a dictionary: {dictionary}")
    for key in keys:
        if dictionary.get(key) is None:
            raise Exception(f"missing key '{key}' in dicionary: {dictionary}")


def config_load(config_file):
    config_dicts = read_yaml_file(config_file)
    for entry in config_dicts:
        validate_dict(
            entry, ["netns_regex", "inotify_actions", "daemon_startup_actions"]
        )
        for inotify_actions in entry["inotify_actions"]:
            for action in inotify_actions:
                if action not in pyinotify.EventsCodes.ALL_FLAGS:
                    raise Exception(f"{action} is not a valid pyinotify event")

    # compile regex now, so they are ready to use later
    for entry in config_dicts:
        new_entry = re.compile(entry["netns_regex"])
        for old_entry in config_dicts:
            if old_entry["netns_regex"] == new_entry:
                raise Exception(f'duplicated netns_regex: {entry["netns_regex"]}')
        entry["netns_regex"] = new_entry

    return config_dicts


def parse_args():
    parser = argparse.ArgumentParser(
        description="Daemon that watches netns events and allows running commands"
    )
    parser.add_argument("--debug", action="store_true", help="To activate debug mode")
    parser.add_argument(
        "--config",
        help="YAML configuration file. Defaults to '%(default)s'",
        default="/etc/wmcs-netns-events-config.yaml",
    )
    parser.add_argument(
        "--list-events", action="store_true", help="list pyinotify events and exit"
    )
    return parser.parse_args()


def cmd_run(cmd):
    logging.info(f"running command: {cmd}")
    r = subprocess.run(cmd, shell=True, capture_output=True)
    if r.returncode != 0:
        logging.warning(f"failed command: {cmd}")
    if r.stderr:
        logging.warning(f"stderr: {r.stderr.decode('utf-8').strip()}")
    if r.stdout:
        logging.info(f"stdout: {r.stdout.decode('utf-8').strip()}")
    return r.returncode


def set_netns_env(netns):
    logging.debug(f"setting env var $NETNS={netns}")
    os.environ["NETNS"] = netns


def run_daemon_startup_actions(configs):
    logging.debug("run_daemon_startup_actions()")
    existing_netns = os.listdir("/var/run/netns/")
    for netns in existing_netns:
        logging.debug(f"evaluating daemon_startup_actions for netns {netns}")
        for config_dict in configs:
            netns_regex = config_dict["netns_regex"]

            if not netns_regex.match(netns):
                # not interested in this netns
                logging.debug(f"regex '{netns_regex.pattern}' didn't match '{netns}'")
                continue

            logging.info(
                f"regex '{netns_regex.pattern}' matched '{netns}', running daemon_startup_actions"
            )
            set_netns_env(netns)
            for cmd in config_dict["daemon_startup_actions"]:
                cmd_run(cmd)


class NetnsEventProcessor(pyinotify.ProcessEvent):
    def __init__(self, configs):
        super()
        self.configs = configs

    def process_default(self, event):
        logging.debug(event)
        for config_dict in self.configs:
            netns_regex = config_dict["netns_regex"]
            if not netns_regex.match(event.name):
                # not interested in any events for this netns
                logging.debug(
                    f"regex '{netns_regex.pattern}' didn't match '{event.name}'"
                )
                continue

            logging.debug(f"regex '{netns_regex.pattern}' matched '{event.name}'")
            for inotify_actions in config_dict["inotify_actions"]:
                for action in inotify_actions:
                    if event.maskname.find(action) < 0:
                        # not interested in this kind of event in this netns
                        logging.debug(
                            f"event maskname {event.maskname} didn't contain {action}"
                        )
                        continue

                    logging.info(
                        f"event on netns '{event.name}' matched '{netns_regex.pattern}' '{action}'"
                    )
                    set_netns_env(event.name)
                    for cmd in inotify_actions[action]:
                        cmd_run(cmd)


def run_loop(configs):
    logging.debug("run_loop()")
    netns_wm = pyinotify.WatchManager()
    netns_handler = NetnsEventProcessor(configs)
    netns_notifier = pyinotify.Notifier(netns_wm, default_proc_fun=netns_handler)
    while True:
        try:
            wd = netns_wm.add_watch(
                "/var/run/netns/", pyinotify.ALL_EVENTS, quiet=False
            )
            for w in wd:
                if wd[w] < 0:
                    logging.critical("Failed to introduce /var/run/netns watch")
                    exit(4)
        except pyinotify.WatchManagerError as e:
            logging.error(f"Trying again, couldn't add the pyinotify watch: {e}")
            time.sleep(1)
            continue
        break

    logging.debug("watch for /var/run/netns suscesfully created, now let's loop()")
    netns_notifier.loop()


def main():
    args = parse_args()

    logging_format = "[%(filename)s] %(levelname)s: %(message)s"
    if args.debug:
        logging_level = logging.DEBUG
    else:
        logging_level = logging.INFO
    logging.basicConfig(format=logging_format, level=logging_level, stream=sys.stdout)

    if args.list_events:
        logging.info("pyinotify events:")
        for flag in pyinotify.EventsCodes.ALL_FLAGS:
            logging.info(flag)
        exit(0)

    if os.getuid() != 0:
        logging.critical("root required")
        exit(1)

    try:
        configs = config_load(args.config)
    except Exception as e:
        logging.critical(f"couldn't validate config from file {args.config}: {e}")
        exit(1)

    logging.debug(f"loaded configuration: {configs}")

    # if /var/run/netns/ doesn't exist, it means the system just booted. Let's create a dummy
    # netns so the dir structure exists and we can watch that directory later
    if not os.path.isdir("/var/run/netns"):
        logging.info("/var/run/netns/ doesn't exist. Briefly creating dummy netns")
        cmd_run("/usr/bin/ip netns add wmcs-netns-events-dummy")
        cmd_run("/usr/bin/ip netns delete wmcs-netns-events-dummy")
    else:
        logging.debug("/var/run/netns/ exists")

    logging.info("starting operations")
    run_daemon_startup_actions(configs)
    run_loop(configs)


if __name__ == "__main__":
    main()
