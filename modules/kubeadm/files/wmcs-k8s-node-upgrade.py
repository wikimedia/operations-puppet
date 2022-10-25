#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

# Read the docs here:
# TODO: https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Kubernetes/Upgrading_Kubernetes

import argparse
import logging
import subprocess
import sys
import time
from datetime import datetime, timedelta

import yaml

DEFAULT_SRC_VERSION = "1.16.10"
DEFAULT_DST_VERSION = "1.17.13"


class Context:
    # don't panic, these yaml are here just to have some example data in case
    # of a dry run, nothing else!
    example1_yaml = """
    apiVersion: v1
    kind: Node
    metadata:
      name: example
    status:
      conditions:
      - status: "True"
        type: Ready
      nodeInfo:
        kubeProxyVersion: v{}
        kubeletVersion: v{}
    """.format(
        DEFAULT_SRC_VERSION, DEFAULT_SRC_VERSION
    )

    example2_yaml = """
    apiVersion: v1
    kind: Node
    metadata:
      name: example
    status:
      conditions:
      - status: "True"
        type: Ready
      nodeInfo:
        kubeProxyVersion: v{}
        kubeletVersion: v{}
    """.format(
        DEFAULT_DST_VERSION, DEFAULT_DST_VERSION
    )

    def __init__(self):
        self.args = None
        self.node_list = []
        self.skip = False
        self.control_fqdn = ""
        self.current_node = ""
        self.current_node_fqdn = ""
        self.current_node_yaml = {}


# our global data, to easily share stuff between different stages
ctx = Context()


def parse_args():
    description = "Utility to automate upgrading a k8s node in our kubeadm-based deployments"
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "--control",
        required=True,
        help="The hostname of the control plane node to use. Typical value are something like "
        "'tools-k8s-control-1' or 'toolsbeta-test-k8s-control-1'. The FQDN will be built using "
        "the project and domain argument",
    )
    parser.add_argument(
        "--project",
        default="toolsbeta",
        help="The CloudVPS project name. Typical values are: 'tools', 'toolsbeta' or 'paws'. "
        "This will be used to build FQDNs. Defaults to '%(default)s'",
    )
    parser.add_argument(
        "--domain",
        default="eqiad1.wikimedia.cloud",
        help="The CloudVPS domain for building FQDNs. Typical value is 'eqiad1.wikimedia.cloud'. "
        "Defaults to '%(default)s'",
    )
    parser.add_argument(
        "--src-version",
        default=DEFAULT_SRC_VERSION,
        help="Source/original kubernetes version. Defaults to '%(default)s'",
    )
    parser.add_argument(
        "--dst-version",
        default=DEFAULT_DST_VERSION,
        help="Destination/target kubernetes version. Defaults to '%(default)s'",
    )
    parser.add_argument(
        "-n",
        "--node",
        action="append",
        help="Hostname of target node to upgrade. Can be specified multiple times for multiple "
        "nodes in the same script run. Can be combined with the '--file' option. The FQDN will "
        "be built using the project and domain argument. Example: -n tools-k8s-worker-1 -n "
        "tools-k8s-worker-2",
    )
    parser.add_argument(
        "--file",
        help="File with a list of target nodes to upgrade. The file should contain a target "
        "hostname per line. The behavior is the same as in the '--node' option, and can be "
        "combined",
    )
    parser.add_argument(
        "-p",
        "--no-pause",
        action="store_true",
        help="If this option is present, this script won't prompt for a confirmation between each "
        "node upgrade",
    )
    parser.add_argument(
        "-d",
        "--dry-run",
        action="store_true",
        help="Dry run: only show what this script would do, but don't do it for real",
    )
    parser.add_argument(
        "-r",
        "--reboot",
        action="store_true",
        help="Reboot the node to have kernel upgrades and similar applied",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="To activate debug mode",
    )

    return parser.parse_args()


def ssh(host, cmd, capture_output=False):
    ssh_cmd = 'ssh -oStrictHostKeyChecking=no {} "{}"'.format(host, cmd)
    if ctx.args.dry_run:
        logging.info("DRY: {}".format(ssh_cmd))
        return

    logging.info(ssh_cmd)
    r = subprocess.run(ssh_cmd, shell=True, capture_output=capture_output)
    if r.returncode != 0:
        logging.critical("failed SSH command, skipping: {}".format(ssh_cmd))
        ctx.skip = True

    if r.stdout:
        return r.stdout.decode("utf-8")


def refresh_current_node_yaml(version):
    cmd = "sudo -i kubectl get node {} -o yaml".format(ctx.current_node)
    output = ssh(ctx.control_fqdn, cmd, capture_output=True)
    if ctx.args.dry_run:
        output = ctx.example1_yaml if version in ctx.args.src_version else ctx.example2_yaml
        logging.warning(
            "DRY: assuming node info: "
            f"{ctx.example1_yaml if version in ctx.args.src_version else ctx.example2_yaml}"
        )
    if output is None:
        logging.error("unable to get node yaml for {}, skipping".format(ctx.current_node))
        ctx.skip = True
        return

    ctx.current_node_yaml = yaml.safe_load(output)


def stage_generate_node_list():
    logging.info("stage: generating node list")
    if ctx.args.file:
        try:
            f = open(ctx.args.file)
            for line in f.readlines():
                if line.strip() != "":
                    ctx.node_list.append(line.strip())
        except OSError as e:
            logging.warning("can't open file: {}".format(e))

    if ctx.args.node:
        for node in ctx.args.node:
            ctx.node_list.append(node)

    nodes = len(ctx.node_list)
    if nodes == 0:
        logging.info("node list is empty. Doing nothing...")
        sys.exit(0)

    logging.debug("node list contains {} elements".format(nodes))


def stage_refresh():
    # this is the first stage. No need to check if this should be skipped.
    logging.info("stage: refreshing node {}".format(ctx.current_node))
    cmd = "sudo puppet agent --enable && sudo run-puppet-agent && sudo apt-get update"
    ssh(ctx.current_node_fqdn, cmd)


def check_package_versions(node_fqdn, package, already_dst_ok=False):
    # get policy information
    cmd = "apt-cache policy {} | egrep Installed\\|Candidate".format(package)
    output = ssh(node_fqdn, cmd, capture_output=True)
    if ctx.args.dry_run:
        output = "Installed: {}\nCandidate: {}".format(ctx.args.src_version, ctx.args.dst_version)
    if output is None:
        logging.warning("couldn't check {} version in {}".format(package, node_fqdn))
        ctx.skip = True
        return

    # this should be something like ['Installed:', '123', 'Candidate:', '234']
    info_array = output.strip().split()
    installed = info_array[1]
    candidate = info_array[3]

    # validate that the installed package version is the right one
    version = installed
    logging.debug(
        "{}: {} installed: {} src_version: {}".format(
            ctx.current_node, package, version, ctx.args.src_version
        )
    )

    if already_dst_ok and ctx.args.dst_version in version:
        # the installed version is the dst version and that's OK!
        logging.debug("{}: {} installed in dst version already".format(ctx.current_node, package))
        return

    if ctx.args.src_version not in version:
        logging.warning(
            "{}: unexpected installed {} deb version ({}), skipping".format(
                ctx.current_node, package, version
            )
        )
        ctx.skip = True
        return

    # validate that the candidate package version is the right one
    version = candidate
    logging.debug(
        "{}: {} candidate: {} dst_version: {}".format(
            ctx.current_node, package, version, ctx.args.dst_version
        )
    )
    if ctx.args.dst_version not in version:
        logging.warning(
            "{}: unexpected candidate {} deb version ({}), skipping".format(
                ctx.current_node, package, version
            )
        )
        ctx.skip = True
        return


def check_current_node_ready():
    # validate that kubernetes sees the node as Ready
    conditions = ctx.current_node_yaml["status"]["conditions"]
    for condition in conditions:
        if condition.get("type") == "Ready" and condition.get("status") == "True":
            logging.debug("node {} is ready".format(ctx.current_node))
            return  # ready!

    logging.warning("current node {} is not ready in k8s".format(ctx.current_node))
    ctx.skip = True


def check_current_node_versions(version):
    # validate that kubernetes sees the right version of kubelet and kube-proxy
    info = ctx.current_node_yaml["status"]["nodeInfo"]
    if version in info.get("kubeletVersion") and version in info.get("kubeProxyVersion"):
        logging.debug("node {} matches version {}".format(ctx.current_node, version))
        return  # OK

    logging.warning(
        (
            "current node {} does not match a component version in k8s, skipping. Version={}, "
            "kubelet version={}, kubeproxy version={}"
        ).format(
            ctx.current_node,
            version,
            info["kubeletVersion"],
            info["kubeProxyVersion"],
        )
    )
    ctx.skip = True


def stage_prechecks():
    # validate the node is ready to be upgraded
    if ctx.skip is True:
        return

    logging.info("stage: prechecks for node {}".format(ctx.current_node))

    refresh_current_node_yaml(ctx.args.src_version)
    if ctx.skip is True:
        return

    check_current_node_ready()
    if ctx.skip is True:
        return

    check_current_node_versions(ctx.args.src_version)
    if ctx.skip is True:
        return

    node_fqdn = ctx.current_node_fqdn
    # if kubeadm is already installed in the dst version, that's OK.
    # given this is the first step in the upgrade stage anyway
    check_package_versions(node_fqdn, "kubeadm", already_dst_ok=True)
    if ctx.skip is True:
        return
    check_package_versions(node_fqdn, "kubectl")
    if ctx.skip is True:
        return
    check_package_versions(node_fqdn, "kubelet")


def stage_drain():
    # drain the node in kubernetes
    if ctx.skip is True:
        return

    logging.info("stage: drain for node {}".format(ctx.current_node))

    args = "--force --ignore-daemonsets --delete-local-data"
    cmd = "sudo -i kubectl drain {} {}".format(args, ctx.current_node)
    ssh(ctx.control_fqdn, cmd)


def stage_reboot():
    if ctx.skip is True:
        return

    logging.info("stage: rebooting node {}".format(ctx.current_node))

    reboot_time = datetime.utcnow()

    ssh(ctx.current_node_fqdn, "sudo systemctl stop kubelet.service docker.service")

    # reboot-host is a WMF specific wrapper: https://wikitech.wikimedia.org/wiki/Cumin#Reboot
    ssh(ctx.current_node_fqdn, "sudo reboot-host")
    if ctx.skip is True or ctx.args.dry_run is True:
        return

    for _ in range(30):
        time.sleep(10)
        output = ssh(ctx.current_node_fqdn, "cat /proc/uptime", capture_output=True)

        # ssh failed: node unreachable
        if ctx.skip is True:
            ctx.skip = False
            continue

        # been up too long: did not reboot yet
        up_seconds = float(output.split(" ")[0])
        if timedelta(seconds=up_seconds) > (datetime.utcnow() - reboot_time):
            continue

        return

    logging.warning("node {} did not reboot in 5 minutes, aborting".format(ctx.current_node))


def stage_upgrade():
    # actually do the upgrade!
    if ctx.skip is True:
        return

    logging.info("stage: upgrade for node {}".format(ctx.current_node))

    pkgs = "kubeadm"
    noprompt = '-o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"'
    cmd = "sudo DEBIAN_FRONTEND=noninteractive apt-get install {} {} -y".format(pkgs, noprompt)
    ssh(ctx.current_node_fqdn, cmd)
    if ctx.skip is True:
        return

    cmd = "sudo kubeadm upgrade node --certificate-renewal=true"
    ssh(ctx.current_node_fqdn, cmd)
    if ctx.skip is True:
        return

    # TODO: verify candidate versions for docker and containerd.io
    pkgs = "kubectl kubelet docker-ce containerd.io"
    noprompt = '-o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"'
    force = "-y --allow-downgrades"
    cmd = "sudo DEBIAN_FRONTEND=noninteractive apt-get install {} {} {}".format(
        pkgs, noprompt, force
    )
    ssh(ctx.current_node_fqdn, cmd)
    if ctx.skip is True:
        return

    cmd = "sudo systemctl restart docker.service kubelet.service"
    ssh(ctx.current_node_fqdn, cmd)


def stage_postchecks():
    # did the upgrade go fine?
    if ctx.skip is True:
        return

    logging.info("stage: postchecks for node {}".format(ctx.current_node))

    refresh_current_node_yaml(ctx.args.dst_version)
    if ctx.skip is True:
        return

    check_current_node_versions(ctx.args.dst_version)


def stage_uncordon():
    # repool the node after the upgrade!
    if ctx.skip is True:
        return

    logging.info("stage: uncordon for node {}".format(ctx.current_node))

    cmd = "sudo -i kubectl uncordon {}".format(ctx.current_node)
    ssh(ctx.control_fqdn, cmd)


def stage_pause():
    # make sure we have time to check everything is OK
    if not ctx.args.no_pause:
        confirm = input("continue? [y/N]: ")
        if confirm[:1] != "y" and confirm[:1] != "Y":
            sys.exit(0)


def main():
    global ctx
    args = parse_args()
    ctx.args = args

    bold_start = "\033[1m"
    bold_end = "\033[0m"
    logging_format = "{}[%(filename)s]{} %(levelname)s: %(message)s".format(bold_start, bold_end)
    if args.debug:
        logging_level = logging.DEBUG
    else:
        logging_level = logging.INFO
    logging.basicConfig(format=logging_format, level=logging_level, stream=sys.stdout)

    ctx.control_fqdn = "{}.{}.{}".format(args.control, args.project, args.domain)

    stage_generate_node_list()
    for node_hostname in ctx.node_list:
        ctx.current_node_fqdn = "{}.{}.{}".format(node_hostname, args.project, args.domain)
        ctx.current_node = node_hostname
        ctx.skip = False

        stage_refresh()
        stage_prechecks()
        stage_drain()
        if args.reboot:
            stage_reboot()
        stage_upgrade()
        stage_postchecks()
        stage_uncordon()
        stage_pause()

    logging.info("nothing else to do")
    sys.exit(0)


if __name__ == "__main__":
    main()
