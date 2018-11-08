#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import logging
import os
import subprocess
import sys


VALID_DOMAINS = ["queue", "hostgroup"]


class GridConfig:
    """Base class for grid configuration objects.  This should be suitable for
    most grid configuration items as subclasses."""

    def __init__(self, conf_type, res_name, addcmd, modcmd, delcmd, getcmd):
        self.conf_type = conf_type
        self.res_name = res_name
        getcmd.append(res_name)
        addcmd.append(res_name)
        modcmd.append(res_name)
        delcmd.append(res_name)
        self.getcmd = getcmd
        self.current_conf = {}
        self.desired_conf = {}
        self.addcmd = addcmd
        self.modcmd = modcmd
        self.delcmd = delcmd

    def compare_and_update(self, input_file, dryrun):
        self.current_conf = self._get_config()
        with open(input_file) as inp_f:
            rawconfig = inp_f.read()

        for x in rawconfig.splitlines():
            if not x.startswith("#"):
                [k, v] = x.split()
                self.desired_conf[k] = v

        if not set(self.desired_conf.keys()) == set(self.current_conf.keys()):
            raise Exception("Configuration file doesn't match existing setup")

        if self.current_conf == self.desired_conf:
            logging.debug("%s matches %s", input_file, self.res_name)
            return True

        if not dryrun:
            result = subprocess.run(self.modcmd.append(input_file), timeout=60)
            return not bool(result.returncode)

        logging.info("%s %s", self.modcmd, input_file)
        return True

    def create(self, input_file, dryrun):
        if not dryrun:
            result = subprocess.run(self.addcmd.append(input_file), timeout=60)
            return not bool(result.returncode)

        logging.info("%s %s", self.addcmd, input_file)
        return True

    def check_exists(self):
        result = subprocess.run(
            self.getcmd, stdout=subprocess.PIPE, timeout=60, check=False
        )
        return not bool(result.returncode)

    def run(self, incoming_config, dryrun):
        if self.check_exists():
            return self.compare_and_update(incoming_config, dryrun)

        return self.create(incoming_config, dryrun)

    def rundel(self):
        return subprocess.run(self.delcmd.append(self.res_name), timeout=60)

    def _get_config(self):
        result = subprocess.run(
            self.getcmd, timeout=60, stdout=subprocess.PIPE, check=True
        )
        current_state = {}
        rawconfig = result.stdout
        for x in rawconfig.splitlines():
            [k, v] = x.split()
            current_state[k] = v

        return current_state


class GridQueue(GridConfig):
    def __init__(self, queue_name):
        super().__init__(
            "queue",
            queue_name,
            ["qconf", "-Aq"],
            ["qconf", "-Mq"],
            ["qconf", "-dq"],
            ["qconf", "-sq"],
        )


class GridHostGroup(GridConfig):
    def __init__(self, group_name):
        super().__init__(
            "hostgroup",
            group_name,
            ["qconf", "-Ahgrp"],
            ["qconf", "-Mhgrp"],
            ["qconf", "-dhgrp"],
            ["qconf", "-shgrp"],
        )

    def _get_config(self):
        result = subprocess.run(
            self.getcmd, timeout=60, stdout=subprocess.PIPE, check=True
        )
        current_state = {}
        rawconfig = result.stdout
        lines = rawconfig.splitlines()
        [k, v] = lines.pop(0).split()  # First line like 'group_name @general'
        current_state.update({k: v})
        hosts = [
            host for l in lines for host in l.split() if host not in ["hostlist", "\\"]
        ]
        current_state["hostlist"] = hosts
        return current_state

    def compare_and_update(self, input_file, dryrun):
        self.current_conf = self._get_config()
        with open(input_file) as inp_f:
            rawconfig = inp_f.read()

        raw_lines = rawconfig.splitlines()
        conf_lines = [x for x in raw_lines if not x.startswith("#")]
        [label1, hostgrp_name] = conf_lines.pop(0).split()
        self.desired_conf[label1] = hostgrp_name
        self.desired_conf["hostlist"] = [
            host for host in conf_lines[0].split() if host != "hostlist"
        ]

        if not set(self.desired_conf.keys()) == set(self.current_conf.keys()):
            raise Exception("Configuration file doesn't match existing setup")

        if self.current_conf == self.desired_conf:
            logging.debug("%s matches %s", input_file, self.res_name)
            return True

        if not dryrun:
            result = subprocess.run(self.modcmd.append(input_file), timeout=60)
            return not bool(result.returncode)

        logging.info("%s %s", self.modcmd, input_file)
        return True


def get_args():
    """Gather arguments from the command line and return help information"""
    argparser = argparse.ArgumentParser(
        "grid_configurator",
        description="Maintain the gridengine configuration in a documented way",
    )

    group = argparser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--domains",
        help=(
            "Specify particular configuration types (such as queue or complex). Multiple"
            " values can be given space-separated."
        ),
        nargs="+",
    )
    group.add_argument(
        "--all-domains",
        help="Check all possible types of config for needed changes",
        action="store_true",
    )
    argparser.add_argument(
        "--config-dir",
        help="Path to find the configuration file",
        default="/data/project/.system_sge/gridengine/etc",
    )
    argparser.add_argument(
        "--dry-run",
        help=(
            "Give this parameter if you don't want the script to actually"
            " make changes."
        ),
        action="store_true",
    )
    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    return argparser.parse_args()


def select_object(obj_type):
    grid_obj_types = {"queue": GridQueue, "hostgroup": GridHostGroup}
    return grid_obj_types[obj_type]


def main():
    args = get_args()
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.INFO,
    )
    domains = []
    if args.domains:
        domains = [dom for dom in args.domains if dom in VALID_DOMAINS]

    if args.all_domains:
        domains = VALID_DOMAINS

    if not domains:
        sys.exit("you have specified no valid grid configuration domains")

    for domain in domains:
        logging.debug("Running configuration updates for %s", domain)
        grid_conf_cls = select_object(domain)
        domain_dir = os.path.join(args.config_dir, domain + "s")
        try:
            conf_files = os.listdir(domain_dir)
        except NameError:
            logging.error(
                "%s is not a valid directory", os.path.join(args.config_dir, domain)
            )
            raise

        for conf in conf_files:
            if conf.startswith("."):
                continue

            grid_conf_obj = grid_conf_cls(conf)
            if grid_conf_obj.check_exists():
                grid_conf_obj.create(os.path.join(domain_dir, conf), args.dry_run)
            else:
                grid_conf_obj.compare_and_update(
                    os.path.join(domain_dir, conf), args.dry_run
                )


if __name__ == "__main__":
    main()
