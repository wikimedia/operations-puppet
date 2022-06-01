#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

# Copyright (c) 2018 Wikimedia Foundation, Inc.
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
#  THIS FILE IS MANAGED BY PUPPET
#

import argparse
import logging
import os
import subprocess
import sys
import re

from typing import List

from keystoneauth1 import session
from keystoneauth1.identity import v3
from keystoneclient.v3 import client as keystone_client
from novaclient import client as novaclient
import yaml


VALID_DOMAINS = ["checkpoint", "queue", "hosts"]
GRID_HOST_TYPE = ["exec", "submit"]
GRID_HOST_PREFIX = {
    # TODO: old name, deprecate once we have no hosts with this name
    "sgewebgrid-generic": ["exec", "submit"],
    "sgewebgen": ["exec", "submit"],
    # TODO: old name, deprecate once we have no hosts with this name
    "sgewebgrid-lighttpd": ["exec", "submit"],
    "sgeweblight": ["exec", "submit"],
    "sgeexec": ["exec", "submit"],
    "sgebastion": "submit",
    "sgecron": "submit",
    "sgegrid": "submit",
    "checker": "submit",
}


def cmd_run(cmd: List[str], **kwargs):
    cmd_string = " ".join(cmd)
    logging.debug(f"running cmd: {cmd_string}")

    r = subprocess.run(cmd_string, capture_output=True, shell=True, **kwargs)

    stderr = r.stderr.decode("utf-8")
    if stderr != "":
        logging.warning(f"command '{cmd_string}' generated stderr: '{stderr}'")

    return r


def sed_replace(filepath: str, string: str, replacement: str):
    try:
        with open(filepath, "rt") as f:
            data = f.read()
            data = data.replace(string, replacement)
        with open(filepath, "wt") as f:
            f.write(data)
    except OSError as error:
        logging.warning(
            f"couldn't replace string '{string}' with '{replacement}' in {filepath}: {error}"
        )


# from https://stackoverflow.com/questions/11809631/fully-qualified-domain-name-validation
fqdn_regex = r"(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)"
fqdn_pattern = re.compile(fqdn_regex, re.IGNORECASE)


def grep_hosts_from_hostlist(filepath: str):
    ret = set()
    with open(filepath, "r") as file:
        for line in file.readlines():
            if not line.startswith("hostlist"):
                # not interested in this line
                continue

            # line is something like:
            # hostlist #@# host1.x.y host2.x.y host3.x.y
            hostlist_content = line.split()[1:]
            for content in hostlist_content:
                # beware, the grid can have weird config stuff in here
                # like '#@#' and other stuff that is clearly not a FQDN
                if fqdn_pattern.match(content):
                    ret.add(content)

    return ret


class GridConfig:
    """Base class for grid configuration objects.  This should be suitable for
    most grid configuration items as subclasses."""

    def __init__(self, conf_type, res_name, addcmd, modcmd, delcmd, getcmd):
        self.conf_type = conf_type
        self.res_name = res_name
        getcmd.append(res_name)
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
                [k, v] = x.split(maxsplit=1)
                self.desired_conf[k] = v

        if not set(self.desired_conf.keys()) == set(self.current_conf.keys()):
            raise Exception("Configuration file doesn't match existing setup")

        if self.current_conf == self.desired_conf:
            logging.debug("%s matches %s", input_file, self.res_name)
            return True

        if not dryrun:
            self.modcmd.append(input_file)
            result = cmd_run(self.modcmd, timeout=60)
            return not bool(result.returncode)

        return True

    def create(self, input_file, dryrun):
        if not dryrun:
            self.addcmd.append(input_file)
            result = cmd_run(self.addcmd, timeout=60)
            return not bool(result.returncode)

        return True

    def check_exists(self):
        try:
            result = cmd_run(self.getcmd, timeout=60)
        except subprocess.CalledProcessError:
            return False

        return not bool(result.returncode)

    def run(self, incoming_config, dryrun):
        if self.check_exists():
            return self.compare_and_update(incoming_config, dryrun)

        return self.create(incoming_config, dryrun)

    def rundel(self):
        return cmd_run(self.delcmd, timeout=60)

    def _get_config(self):
        result = cmd_run(self.getcmd, timeout=60)
        current_state = {}
        last_key = ""
        rawconfig = result.stdout.decode("utf-8")
        for x in rawconfig.splitlines():
            if not x.endswith("\\") and len(x.split(maxsplit=1)) == 2:
                [k, v] = x.split(maxsplit=1)
                current_state[k] = v
            elif len(x.split(maxsplit=1)) == 2:
                x_stripped = x.rstrip("\\")
                if len(x_stripped.split(maxsplit=1)) > 1:
                    [k, v] = x_stripped.split(maxsplit=1)
                    last_key = k
                    current_state[k] = v
                else:
                    current_state[last_key] += x_stripped.strip()
            else:
                current_state[last_key] += x.strip()

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


class GridChkPt(GridConfig):
    def __init__(self, queue_name):
        super().__init__(
            "checkpoint",
            queue_name,
            ["qconf", "-Ackpt"],
            ["qconf", "-Mckpt"],
            ["qconf", "-dckpt"],
            ["qconf", "-sckpt"],
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
        result = cmd_run(self.getcmd, timeout=60)
        current_state = {}
        rawconfig = result.stdout.decode("utf-8")  # You get bytes out of this.
        lines = rawconfig.splitlines()
        [k, v] = lines.pop(0).split(maxsplit=1)  # First line like 'group_name @general'
        current_state.update({k: v})
        hosts = [host for x in lines for host in x.split() if host not in ["hostlist", "\\"]]
        current_state["hostlist"] = hosts
        return current_state

    def compare_and_update(self, input_file, dryrun, host_processor):
        self.current_conf = self._get_config()
        with open(input_file) as inp_f:
            rawconfig = inp_f.read()

        raw_lines = rawconfig.splitlines()
        conf_lines = [x for x in raw_lines if not x.startswith("#")]
        [label1, hostgrp_name] = conf_lines.pop(0).split(maxsplit=1)
        self.desired_conf[label1] = hostgrp_name
        self.desired_conf["hostlist"] = [
            host
            for host in conf_lines[0].split()
            if host != "hostlist" and host in host_processor.host_set["exec"]
        ]

        if not set(self.desired_conf.keys()) == set(self.current_conf.keys()):
            logging.debug("Desired conf keys: %s", self.desired_conf.keys())
            logging.debug("Current conf keys: %s", self.current_conf.keys())
            raise Exception("Configuration file doesn't match existing setup")

        if self.current_conf == self.desired_conf:
            logging.debug("%s matches %s", input_file, self.res_name)
            return True

        if not dryrun:
            self.modcmd.append(input_file)
            result = cmd_run(self.modcmd, timeout=60)
            return not bool(result.returncode)

        return True


class GridExecHost(GridConfig):
    def __init__(self, host_name):
        super().__init__(
            "hostgroup",
            host_name,
            ["qconf", "-Ae"],
            ["qconf", "-Me"],
            ["qconf", "-de"],
            ["qconf", "-se"],
        )

    def compare_and_update(self, input_file, dryrun):
        self.current_conf = self._get_config()
        with open(input_file) as inp_f:
            rawconfig = inp_f.read()

        for x in rawconfig.splitlines():
            if not x.startswith("#"):
                [k, v] = x.split(maxsplit=1)
                self.desired_conf[k] = v

        # We don't check the file format.  Be careful.
        # Also, only check certain, configurable values, for now just complexes
        if self.current_conf["complex_values"] == self.desired_conf["complex_values"]:
            logging.debug("%s matches %s", input_file, self.res_name)
            return True

        if not dryrun:
            self.modcmd.append(input_file)
            result = cmd_run(self.modcmd, timeout=60)
            return not bool(result.returncode)

        return True


class HostProcessor:
    """Object to manage the gathering of hostname information from Keystone and
    application of it to the grid itself"""

    def __init__(
        self,
        keystone_url,
        observer_pass,
        host_prefixes,
        beta,
        config_dir,
        grid_root: str,
        host_types,
    ):
        self.keystone_url = keystone_url
        self.observer_pass = observer_pass
        self.project = "toolsbeta" if beta else "tools"
        self.regions = self._get_regions()
        self.os_instances = {}
        self.host_set = self._hosts(host_prefixes, host_types)
        self.legacy_domain = f"{self.project}.eqiad.wmflabs"
        self.config_dir = config_dir
        self.grid_root = grid_root

    def _get_regions(self):
        client = keystone_client.Client(
            session=session.Session(
                auth=v3.Password(
                    auth_url=self.keystone_url,
                    username="novaobserver",
                    password=self.observer_pass,
                    project_name="observer",
                    user_domain_name="default",
                    project_domain_name="default",
                )
            ),
            interface="public",
        )
        return [region.id for region in client.regions.list()]

    def _hosts(self, host_prefixes, host_types):
        host_set = {name: [] for name in host_types}
        for region in self.regions:
            client = novaclient.Client(
                "2.0",
                session=session.Session(
                    auth=v3.Password(
                        auth_url=self.keystone_url,
                        username="novaobserver",
                        password=self.observer_pass,
                        project_name=self.project,
                        user_domain_name="default",
                        project_domain_name="default",
                    )
                ),
                region_name=region,
            )

            # region is like 'whatever-r', remove trailing '-r', the domain doesn't have it
            domain = f"{self.project}.{region[:-2]}.wikimedia.cloud"

            self.os_instances[region] = client.servers.list()
            if len(self.os_instances[region]) == 0:
                logging.error("empty instance list from openstack is likely an error")
                sys.exit(1)

            for instance in self.os_instances[region]:
                name = instance.name
                for prefix in host_prefixes:
                    full_prefix = "{}-{}".format(self.project, prefix)
                    if name.startswith(full_prefix):
                        role = host_prefixes[prefix]
                        if isinstance(role, list):
                            for r in role:
                                host_set[r].append(f"{name}.{domain}")
                        else:
                            host_set[role].append(f"{name}.{domain}")
        return host_set

    def _host_exists(self, hostname: str):
        for region in self.regions:
            for vm in self.os_instances[region]:
                if hostname == vm.name:
                    return True

        # NOTE: always assume master/shadow exists, even if the VM is transiently not there.
        # You DON'T want to destroy master/shadow configuration by assuming they're not there.
        # Hardcoded, I know. Hopefully grid is deprecated before we introduce a new pattern here.
        master = f"{self.project}-sgegrid-master"
        shadow = f"{self.project}-sgegrid-shadow"
        if hostname == master or hostname == shadow:
            logging.warning(f"{hostname} is not an openstack VM ?! Continuing now, but REVIEW IT")
            return True

        return False

    def _handle_dead_store(self, dry_run):
        basedir = f"{self.grid_root}/store"
        try:
            dir_list = os.listdir(basedir)
        except OSError as error:
            logging.warning(f"unable to list directory {basedir}: {error}")
            return

        # files may be:
        # execnode-hostname1.domain.tld
        # hostkey-hostname1.domain.tld
        # submithost-hostname1.domain.tld
        known_prefixes = {"execnode", "hostkey", "submithost"}

        for file in dir_list:
            fullpath = f"{basedir}/{file}"
            logging.debug(f"detected file in grid store {fullpath}, evaluating if dead config")

            prefix = file.split("-")[0]
            if prefix not in known_prefixes:
                logging.warning(f"unknown file prefix: {fullpath}, we only know {known_prefixes}")
                continue

            fqdn = "-".join(file.split("-")[1:])
            hostname = fqdn.split(".")[0]

            if self._host_exists(hostname):
                continue

            if dry_run:
                logging.info(f"would delete file {fullpath}, VM doesn't exists (dry run)")
            else:
                logging.info(f"deleting file {fullpath}, VM doesn't exists")
                try:
                    os.remove(fullpath)
                except OSError as error:
                    logging.warning(f"unable to delete dead file {fullpath}: {error}")

    def _handle_dead_config_dir(self, directory: str, dry_run):
        dir = os.path.join(self.grid_root, directory)
        try:
            dir_list = os.listdir(dir)
        except OSError as error:
            logging.warning(f"unable to list directory {dir}: {error}")
            return

        for host in dir_list:
            file = f"{dir}/{host}"
            hostname = host.split(".")[0]

            logging.debug(f"detected host file for {hostname} ({file}), evaluating if dead config")
            if not self._host_exists(hostname):
                if dry_run:
                    logging.info(f"would remove {file}, '{hostname}' is not a VM (dry run)")
                else:
                    logging.info(f"removing {file}, '{hostname}' is not a VM")
                    try:
                        if os.path.isfile(file):
                            os.remove(file)
                        elif os.path.isdir(file):
                            os.rmdir(file)
                        else:
                            logging.warning(f"we don't know what {file} is, so cannot delete it")
                    except OSError as error:
                        logging.warning(f"couldn't remove {file}: {error}")

    def _handle_dead_config_hostlist(self, filetype: str, dry_run):
        dir = os.path.join(self.config_dir, filetype)
        try:
            listing = os.listdir(dir)
        except OSError as error:
            logging.warning(f"unable to list directory {dir}: {error}")
            return

        for file in listing:
            fullpath = f"{dir}/{file}"

            logging.debug(f"evaluating if {fullpath} has dead config in the 'hostlist' paremeter")
            hosts = grep_hosts_from_hostlist(fullpath)
            for host in hosts:
                hostname = host.split(".")[0]
                if not self._host_exists(hostname):
                    if dry_run:
                        logging.info(
                            f"would rm '{host}' from 'hostlist' parameter at {fullpath} (dry run)"
                        )
                    else:
                        logging.info(
                            f"removing mention to '{host}' from 'hostlist' parameter at {fullpath}"
                        )
                        sed_replace(fullpath, host, "")

    def _handle_dead_config(self, dry_run):
        self._handle_dead_store(dry_run)
        self._handle_dead_config_dir("gridengine/collectors/queues", dry_run)
        self._handle_dead_config_dir("gridengine/collectors/hostgroups", dry_run)

        # TODO: the next few ones may clash with the rest of the logic in this script
        # turn them into dry mode for now. May delete later
        self._handle_dead_config_dir("gridengine/etc/hosts", dry_run=True)
        self._handle_dead_config_hostlist("hostgroups", dry_run=True)
        self._handle_dead_config_hostlist("queues", dry_run=True)

    def run_updates(self, dry_run, host_types):
        # pre-step: check for dead configuration that may prevent any further changes to
        # the grid configuration. Dead config happens when a VM is deleted but we still
        # have config files referencing the now missing VM
        self._handle_dead_config(dry_run)

        for host_class in sorted(host_types):
            self._run_updates(dry_run, host_types, host_class)

    def _run_updates(self, dry_run, host_types, host_class):
        if host_class == "exec":
            get_arg = "-sel"
            add_arg = "-Ae"
            del_arg = "-de"
            exec_host_dir = os.path.join(self.config_dir, "exechosts")
            try:
                conf_files = os.listdir(exec_host_dir)
            except NameError:
                logging.error("%s is not a valid directory", os.path.join(exec_host_dir))
                raise

            exec_conf_files = [c for c in conf_files if not c.startswith(".")]
        else:
            get_arg = "-s{}".format(host_class[0])
            add_arg = "-a{}".format(host_class[0])
            del_arg = "-d{}".format(host_class[0])

        result = cmd_run(["qconf", get_arg], timeout=60)
        current_hosts = result.stdout.decode("utf-8").splitlines()

        # additional step: cleanup duplicate hosts that may exist. We know this is
        # happening if there are 2 hosts with the exact same hostname but different
        # domain (legacy vs new). Leave the legacy one, for manual cleanup
        for current_host in current_hosts[:]:
            if not current_host.endswith(self.legacy_domain):
                # already configured host but it uses the new domain. This is fine, continue
                # with normal script operations
                continue

            # there is a host using the legacy domain. Do we have a host with the same hostname
            # in the list of new domain hosts? If so, remove the duplicate.
            current_host_hostname = current_host.split(".")[0]
            for nova_host in self.host_set[host_class][:]:
                nova_host_hostname = nova_host.split(".")[0]
                if current_host_hostname == nova_host_hostname:
                    logging.debug(f"Leaving {current_host} as is instead of using {nova_host}")
                    self.host_set[host_class].remove(nova_host)
                    current_hosts.remove(current_host)

        for host in self.host_set[host_class]:
            if host_class == "exec":
                if host in current_hosts and host in exec_conf_files:
                    # Here we need to check for config changes
                    grid_exec_host = GridExecHost(host)
                    grid_exec_host.compare_and_update(os.path.join(exec_host_dir, host), dry_run)
                    current_hosts.remove(host)
                    continue
                elif host in current_hosts:
                    # Oops - no host config
                    logging.warning("%s cannot be added without a config file", host)
                    current_hosts.remove(host)
                    continue
                elif host not in exec_conf_files:
                    # Oops - no host config
                    logging.warning("%s cannot be added without a config file", host)
                    continue

                # Add the host
                this_host_config = os.path.join(self.config_dir, "exechosts", host)
                if not dry_run:
                    result = cmd_run(["qconf", add_arg, this_host_config], timeout=60)
                else:
                    logging.info("Would run: qconf {} {}".format(add_arg, this_host_config))

            else:
                if host in current_hosts:
                    current_hosts.remove(host)
                    continue

                if not dry_run:
                    result = cmd_run(["qconf", add_arg, host], timeout=60)
                else:
                    logging.info("Would run: qconf {} {}".format(add_arg, host))

        if current_hosts:
            # This suggests there are hosts listed that don't exist and must
            # be expunged
            for host in current_hosts:
                if not dry_run:
                    result = cmd_run(
                        ["qconf", del_arg, host],
                        timeout=60,
                    )
                else:
                    logging.info(
                        "Would delete {} host: qconf {} {}".format(host_class, del_arg, host)
                    )


# Utility Functions
def get_args():
    """Gather arguments from the command line and return help information"""
    argparser = argparse.ArgumentParser(
        "grid_configurator",
        description="Maintain the gridengine configuration in a documented way",
    )

    group = argparser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--domain",
        help="Particular configuration types. Can be specified multiple times. "
        "Valid values are: {}".format(", ".join(VALID_DOMAINS)),
        action="append",
        choices=VALID_DOMAINS,
    )
    group.add_argument(
        "--all-domains",
        help="Check all possible types of config for needed changes",
        action="store_true",
    )
    argparser.add_argument(
        "--config-dir",
        help="Filesystem absolute path to find the configuration file. Defaults to '%(default)s'",
        default="/data/project/.system_sge/gridengine/etc",
    )
    argparser.add_argument(
        "--grid-root",
        help="Location of the grid root. Defaults to '%(default)s'",
        default="/data/project/.system_sge",
    )
    argparser.add_argument(
        "--keystone-url",
        help="Endpoint for openstack keystone. Only for hosts. Defaults to '%(default)s'",
        default="https://openstack.eqiad1.wikimediacloud.org:25000/v3",
    )

    argparser.add_argument(
        "--observer-pass",
        help="Read-only password to use for Keystone when calling OpenStack -- only for hosts",
        default="",  # Should not be required unless all-domains or domains includes hosts
    )

    argparser.add_argument(
        "--beta",
        help="Required for running on toolsbeta for hosts, "
        "otherwise, this assumes Toolforge proper",
        default=False,
        action="store_true",
    )

    argparser.add_argument(
        "--dry-run",
        help="Give this parameter if you don't want the script to actually" " make changes.",
        action="store_true",
    )
    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    args = argparser.parse_args()
    if args.all_domains or "hosts" in args.domain:
        if not args.observer_pass:
            if os.path.isfile("/etc/novaobserver.yaml"):
                with open("/etc/novaobserver.yaml") as conf_fh:
                    nova_observer_config = yaml.safe_load(conf_fh)

                args.observer_pass = nova_observer_config["OS_PASSWORD"]
            else:
                argparser.error("To process hosts the --observer-pass argument is required")

    return args


def select_object(obj_type):
    grid_obj_types = {
        "queue": GridQueue,
        "hostgroup": GridHostGroup,
        "checkpoint": GridChkPt,
    }
    return grid_obj_types[obj_type]


def run_domain_updates(config_dir, domain, grid_class, dry_run, *args):
    domain_dir = os.path.join(config_dir, domain + "s")
    try:
        conf_files = os.listdir(domain_dir)
    except NameError:
        logging.error("%s is not a valid directory", os.path.join(config_dir, domain))
        raise

    for conf in conf_files:
        if conf.startswith("."):
            continue

        grid_object = grid_class(conf)
        obj_args = (os.path.join(domain_dir, conf), dry_run) + args
        if not grid_object.check_exists():
            grid_object.create(*obj_args)
        else:
            grid_object.compare_and_update(*obj_args)


def main():
    args = get_args()
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.INFO,
    )
    if args.all_domains:
        domains = VALID_DOMAINS
    else:
        domains = args.domain

    if not domains:
        sys.exit("you have specified no valid grid configuration domains")

    try:
        f = open("/etc/wmcs-project")
        for line in f.readlines():
            if line[:-1] == "tools" and args.beta:
                f.close()
                logging.error("Running in 'tools' project with --beta makes no sense")
                sys.exit(1)
            if line[:-1] != "tools" and not args.beta:
                f.close()
                logging.error("If running in a project other than 'tools' you need --beta")
                sys.exit(1)
            # that file should only have 1 line
            break
        f.close()

    except Exception as e:
        logging.warning(f"Failed to read /etc/wmcs-project file {e}. Project won't be validated.")

    if "hosts" in domains:
        logging.debug("Running configuration updates for hosts")
        host_processor = HostProcessor(
            args.keystone_url,
            args.observer_pass,
            GRID_HOST_PREFIX,
            args.beta,
            args.config_dir,
            args.grid_root,
            GRID_HOST_TYPE,
        )

        run_domain_updates(
            args.config_dir, "hostgroup", GridHostGroup, args.dry_run, host_processor
        )

        host_processor.run_updates(args.dry_run, GRID_HOST_TYPE)

    for domain in domains:
        if domain == "hosts":
            continue

        grid_conf_cls = select_object(domain)
        logging.debug("Running configuration updates for %s", domain)
        run_domain_updates(args.config_dir, domain, grid_conf_cls, args.dry_run)


if __name__ == "__main__":
    main()
