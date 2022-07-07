#!/usr/bin/env python3
"""
Full stack instance life cycle testing.  Meant to be run
as a daemon and then also adhoc for testing.

Guidelines for verification phases:
- Phases are independent as much as possible
- Wrapped with a get_timer function
- Return only time executed and created object(s) where applicable
- raise exception on timeout or failure
- Wait for confirmation of operation success

We use this to track baselines over time for the basic
instance lifecycle, and in case of pipeline failure the service
alerts on failure.

Expects env variables inline with our other nova tooling:
    'OS_PASSWORD'
    'OS_USERNAME'
    'OS_PROJECT_ID'
"""

import argparse
import json
import logging
import os
import socket
import subprocess
import sys
import time
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from pathlib import Path
from types import TracebackType
from typing import Any, Dict, List, Optional, Tuple, Type, Union

import novaclient
import yaml
from keystoneauth1 import session as keystone_session
from keystoneauth1.identity.v3 import Password as KeystonePassword
from novaclient import client as nova_client
from novaclient.v2.client import Client as NovaClient
from novaclient.v2.flavors import Flavor
from novaclient.v2.images import Image
from novaclient.v2.servers import Server

LOGGER = logging.getLogger(__name__)


PROMETHEUS_FILE = Path("/var/lib/prometheus/node.d/novafullstack.prom")


class Deployment(Enum):
    EQIAD1 = "eqiad1"
    CODFW1DEW = "codfw1dev"

    def __str__(self) -> str:
        return self.value


@contextmanager
def get_timer():
    """Simple timer contextmanager.

    Example usage:
    with get_timer() as get_elapsed_time():
        ...
        get_elapsed_time()  # returns the time passed since the start
        ...

    get_elapsed_time()  # returns the time it took to run the with block
    """
    start_time = time.perf_counter()
    elapsed_time = None
    yield lambda: elapsed_time or (time.perf_counter() - start_time)
    elapsed_time = time.perf_counter()


class ECSFormatter(logging.Formatter):
    """ECS 1.7.0 logging formatter"""

    def __init__(self):
        super().__init__()
        self.hostname = ""

    def format(self, record: logging.LogRecord) -> str:
        ecs_message = {
            "ecs.version": "1.7.0",
            "log.level": record.levelname.upper(),
            "log.origin.file.line": record.lineno,
            "log.origin.file.name": record.filename,
            "log.origin.file.path": record.pathname,
            "log.origin.function": record.funcName,
            "labels": {"test_hostname": self.hostname},
            "message": record.getMessage(),
            "process.name": record.processName,
            "process.thread.id": record.process,
            "process.thread.name": record.threadName,
            "timestamp": datetime.utcnow().isoformat(),
        }
        if record.exc_info:
            ecs_message["error.stack"] = self.formatException(record.exc_info)
        if not ecs_message.get("error.stack") and record.exc_text:
            ecs_message["error.stack"] = record.exc_text
        # Prefix "@cee" cookie indicating rsyslog should parse the message as JSON
        return f"@cee: {json.dumps(ecs_message)}"

    def set_hostname(self, hostname: str) -> None:
        self.hostname = hostname


def log_unhandled_exception(
    exc_type: Type[BaseException],
    exc_value: BaseException,
    exc_traceback: Optional[TracebackType],
) -> None:
    """Forwards unhandled exceptions to log handler.  Override sys.excepthook to activate."""
    LOGGER.exception(
        "Unhandled exception: %s",
        exc_value,
        exc_info=(exc_type, exc_value, exc_traceback),
    )


def ask_confirmation(prompt: str) -> bool:
    """Ask a yes/no question."""
    while True:
        inp = input(f"{prompt} [yN]:")
        if inp.lower() == "y":
            return True
        if not inp or inp.lower() == "n":
            return False

        print(f"Invalid input {inp}, please try again.")


def run_remote(
    node: str,
    username: str,
    keyfile: str,
    bastion_ip: str,
    cmd: str,
    debug: bool = False,
) -> str:
    """Execute a remote command using SSH.

    Return the output of the command.
    """

    # Possible LogLevel values
    #  QUIET, FATAL, ERROR, INFO, VERBOSE, DEBUG
    # NumberOfPasswordPrompts=0 instructs not to
    # accept a password prompt.
    ssh = [
        "/usr/bin/ssh",
        "-o",
        "ConnectTimeout=5",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "NumberOfPasswordPrompts=0",
        "-o",
        f"LogLevel={'DEBUG' if debug else 'ERROR'}",
        "-o",
        (
            f'ProxyCommand="ssh -o StrictHostKeyChecking=no -i {keyfile} -W %h:%p '
            f'{username}@{bastion_ip}"'
        ),
        "-i",
        keyfile,
        f"{username}@{node}",
    ]

    full_cmd = ssh + cmd.split(" ")
    LOGGER.debug(" ".join(full_cmd))

    # The nested nature of the proxycommand line is baffling to
    #  subprocess and/or ssh; joining a full shell commandline
    #  works and gives us something we can actually test by hand.
    return subprocess.check_output(
        " ".join(full_cmd), shell=True, stderr=subprocess.STDOUT
    ).decode("utf-8")


def run_local(cmd: List[str]) -> bytes:
    """Execute a remote command using SSH."""
    LOGGER.debug(" ".join(cmd))
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT)


def verify_dns(
    hostname: str, expected_ip: str, nameservers: List[str], timeout: float = 2.0
) -> float:
    """Ensure dns resolution for the created VM.

    Return the time it took to run.
    """
    with get_timer() as get_elpased_time:
        LOGGER.info("Resolving %s from %s", hostname, nameservers)
        dig_query = ["/usr/bin/dig"]
        for server in nameservers:
            dig_query.append(f"@{server}")
        dig_query.append(hostname)
        dig_options = ["+short", "+time=2", "+tries=1"]

        while True:
            out = run_local(dig_query + dig_options)
            LOGGER.debug(out)

            if out.decode("utf8").strip() == expected_ip.strip():
                # Success
                break

            if out:
                raise Exception(
                    f"DNS failure: got the wrong IP {out.decode('utf8').strip()} for hostname "
                    f"{hostname}; expected {expected_ip}"
                )

            # If we got here then dig returned an empty string which suggests NXDOMAIN.
            # wait and see if something shows up.
            if get_elpased_time() >= timeout:
                raise Exception(f"Timed out waiting for A record for {hostname}")

            time.sleep(1)

    return get_elpased_time()


def verify_dns_reverse(
    hostname: str, ipaddr: str, nameservers: List[str], timeout: float = 2.0
) -> float:
    """Ensure reverse dns resolution for the created VM.

    Return the time it took to run.
    """
    with get_timer() as get_elapsed_time:
        LOGGER.info("Resolving %s from %s", ipaddr, nameservers)
        dig_query = []
        dig_query.append("/usr/bin/dig")
        for server in nameservers:
            dig_query.append(f"@{server}")
        dig_query.append("-x")
        dig_query.append(ipaddr)
        dig_options = ["+short", "+time=2", "+tries=1"]

        while True:
            out = run_local(dig_query + dig_options)
            LOGGER.debug(out)

            if out.decode("utf8").strip().strip(".") == hostname.strip():
                # Success
                break

            if out:
                raise Exception(
                    f"DNS -x failure: got the wrong hostname {out.decode('utf8').strip()} for ip "
                    f"{ipaddr}; expected {hostname}"
                )

            # If we got here then dig returned an empty string which suggests NXDOMAIN.
            # wait and see if something shows up.
            if get_elapsed_time() >= timeout:
                raise Exception(f"Timed out waiting for ptr record for {ipaddr}")

            time.sleep(1)

    return get_elapsed_time()


def verify_dns_cleanup(
    hostname: str, nameservers: List[str], timeout: float = 2.0
) -> float:
    """Ensure the DNS entry was cleared.

    Return the time it took to run.
    """
    with get_timer() as get_elapsed_time:
        LOGGER.info("Resolving %s from %s, waiting for cleanup", hostname, nameservers)
        while True:
            time.sleep(10)
            dig_query = []
            dig_query.append("/usr/bin/dig")
            for server in nameservers:
                dig_query.append(f"@{server}")
            dig_query.append(hostname)
            dig_options = ["+short", "+time=2", "+tries=1"]
            out = run_local(dig_query + dig_options)
            if not out:
                break
            if get_elapsed_time() >= timeout:
                raise Exception(f"Failed to clean up dns for {hostname}")
    return get_elapsed_time()


def verify_dns_reverse_cleanup(
    ipaddr: str, nameservers: List[str], timeout: float = 2.0
) -> float:
    """Ensure the DNS entry was cleared

    Return the time it took to run.
    """
    with get_timer() as get_elapsed_time:
        LOGGER.info("Resolving %s from %s, waiting for cleanup", ipaddr, nameservers)
        while True:
            time.sleep(10)
            dig_query = []
            dig_query.append("/usr/bin/dig")
            for server in nameservers:
                dig_query.append(f"@{server}")
            dig_query.append("-x")
            dig_query.append(ipaddr)
            dig_options = ["+short", "+time=2", "+tries=1"]
            out = run_local(dig_query + dig_options)
            if not out:
                break
            if get_elapsed_time() >= timeout:
                raise Exception(f"Failed to clean up dns ptr record for {ipaddr}")
    return get_elapsed_time()


def verify_ssh(
    address: str, user: str, keyfile: str, bastion_ip: str, timeout: int
) -> float:
    """Ensure SSH works to an instance.

    Returns the time it took to run.
    """
    with get_timer() as get_elapsed_time:
        LOGGER.info("SSH to %s", address)
        while True:
            time.sleep(10)
            try:
                run_remote(
                    node=address,
                    username=user,
                    keyfile=keyfile,
                    bastion_ip=bastion_ip,
                    cmd="/bin/true",
                )
                break
            except subprocess.CalledProcessError as error:
                LOGGER.debug(error)
                LOGGER.debug("SSH waited for %d (of %d)", get_elapsed_time(), timeout)

            if get_elapsed_time() >= timeout:
                raise Exception(f"SSH for {address} timed out")
    return get_elapsed_time()


def verify_puppet(
    address: str, user: str, keyfile: str, bastion_ip: str, timeout: int
) -> Tuple[float, Dict[str, Any]]:
    """Ensure Puppet has run on an instance.

    Returns the elapsed time, and the puppet run summary.
    """
    with get_timer() as get_elapsed_time:
        LOGGER.info("Verify Puppet run on %s", address)
        while True:
            out = "No command run yet"
            try:
                cat_summary = "sudo cat /var/lib/puppet/state/last_run_summary.yaml"
                out = run_remote(
                    node=address,
                    username=user,
                    keyfile=keyfile,
                    bastion_ip=bastion_ip,
                    cmd=cat_summary,
                )
                break
            except subprocess.CalledProcessError as error:
                LOGGER.debug(error)
                LOGGER.debug(error.stdout)
                out = error.stdout
                LOGGER.debug("Puppet wait %d", get_elapsed_time())

            if get_elapsed_time() > timeout:
                raise Exception(
                    f"Timed out trying to verify puppet for {address}, last check run output: "
                    f"{out}"
                )
            time.sleep(10)

    LOGGER.debug(out)
    try:
        last_run_summary = yaml.safe_load(out)
    except yaml.YAMLError:
        LOGGER.warning("Yaml conversion failed for Puppet results")
        last_run_summary = {}

    LOGGER.debug(last_run_summary)
    return (get_elapsed_time(), last_run_summary)


def verify_create(
    nova_connection: NovaClient,
    name: str,
    image: Image,
    flavor: Flavor,
    timeout: int,
    network: str,
    on_host: Optional[str] = None,
) -> Tuple[float, Server]:
    """Create and ensure creation for an instance.

    Returns the elapsed time in seconds and the new server.
    """

    with get_timer() as get_elapsed_time:
        LOGGER.info("Creating %s", name)
        if on_host:
            availability_zone = f"server:{on_host}"
        else:
            availability_zone = None

        if network:
            nics = [{"net-id": network}]
        else:
            nics = None

        new_vm: Server = nova_connection.servers.create(
            name=name,
            image=image.id,
            flavor=flavor.id,
            nics=nics,
            availability_zone=availability_zone,
        )
        while True:
            new_vm: Server = nova_connection.servers.get(new_vm.id)
            if new_vm.status == "ACTIVE":
                break
            elapsed_time = get_elapsed_time()
            LOGGER.debug("Creation at %ds", elapsed_time)
            if elapsed_time > timeout:
                raise Exception(f"Creation of {new_vm.id} timed out")
            time.sleep(10)
    return get_elapsed_time(), new_vm


def verify_deletion(nova_cli: NovaClient, vm: Server, timeout: float) -> float:
    """Delete and ensure deletion of an instance."""

    with get_timer() as get_elapsed_time:
        LOGGER.info("Removing %s", vm.human_id)
        vm.delete()
        while True:
            try:
                nova_cli.servers.get(vm.id)
            except novaclient.exceptions.NotFound:
                LOGGER.info("%s successfully removed", vm.human_id)
                break

            if get_elapsed_time() > timeout:
                raise Exception("{server.human_id} deletion timed out")
            time.sleep(30)
    return get_elapsed_time()


class StatHandler:
    def __init__(self, statsd_host: str):
        self.stats: Dict[str, Union[int, float]] = {}
        self.statsd_host = statsd_host
        self.metric_prefix = "cloudvps.novafullstack"

    def add_stat(self, stat_name: str, stat_value: Union[int, float]) -> None:
        # For prometheus
        metric_name = f"{self.metric_prefix}.{stat_name}"
        self.stats[metric_name] = stat_value

        # for statsd
        statsd_metric_name = f"{self.metric_prefix}.{socket.gethostname()}.{stat_name}"
        my_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        my_socket.connect((self.statsd_host, 8125))
        my_socket.send(f"{statsd_metric_name}:{stat_value}|g".encode("utf8"))
        LOGGER.info("%s => %f %d", metric_name, stat_value, int(time.time()))

    def flush_stats(self) -> None:
        with PROMETHEUS_FILE.open("w", encoding="utf-8") as prom_fd:
            for metric_name, stat_value in self.stats.items():
                safe_metric_name = metric_name.replace(".", "_").replace("-", "_")
                prom_fd.write(f"# TYPE {safe_metric_name} gauge\n")
                prom_fd.write(f"{safe_metric_name} {stat_value}\n")

        self.stats = {}


def get_args() -> argparse.Namespace:
    argparser = argparse.ArgumentParser()

    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    argparser.add_argument(
        "--project", default="admin-monitoring", help="Set project to test creation for"
    )

    argparser.add_argument(
        "--keyfile", default="", help="Path to SSH key file for verification"
    )

    argparser.add_argument(
        "--bastion-ip", default="", help="IP of bastion to use for ssh tests"
    )

    argparser.add_argument(
        "--user",
        default="",
        help="Set username (Expected to be the same across all backends)",
    )

    argparser.add_argument(
        "--puppetmaster", default="", help="fqdn of the cloud frontend puppetmaster"
    )

    argparser.add_argument(
        "--prepend",
        default="test-create",
        help="String to add to beginning of instance names",
    )

    argparser.add_argument(
        "--max-pool", default=1, type=int, help="Allow this many instances"
    )

    argparser.add_argument(
        "--preserve-leaks", help="Never delete failed VMs", action="store_true"
    )

    argparser.add_argument(
        "--keystone-url",
        default=None,
        help=(
            "Auth url for token and service discovery (will use "
            "https://openstack.<deployment>.wikimediacloud.org:25357/v3 as default)"
        ),
    )

    argparser.add_argument(
        "--interval",
        default=600,
        type=int,
        help="Seconds delay for daemon (default: 600 [10m]), if set to 0 it will only run once",
    )

    argparser.add_argument(
        "--creation-timeout",
        default=180,
        type=int,
        help="Allow this long for creation to succeed.",
    )

    argparser.add_argument(
        "--ssh-timeout",
        default=180,
        type=int,
        help="Allow this long for SSH to succeed.",
    )

    argparser.add_argument(
        "--puppet-timeout",
        default=120,
        type=int,
        help="Allow this long for Puppet to succeed.",
    )

    argparser.add_argument(
        "--deletion-timeout",
        default=120.0,
        type=float,
        help="Allow this long for delete to succeed.",
    )

    argparser.add_argument("--image", default="debian-10.0-buster", help="Image to use")

    argparser.add_argument("--flavor", default="m1.small", help="Flavor to use")

    argparser.add_argument(
        "--skip-puppet", help="Turn off Puppet validation", action="store_true"
    )

    argparser.add_argument(
        "--skip-dns", help="Turn off DNS validation", action="store_true"
    )

    argparser.add_argument(
        "--dns-resolvers",
        help="Comma separated list of nameservers",
        default=["208.80.154.143", "208.80.154.24"],
        type=lambda servers_str: [server.strip() for server in servers_str.split(",")],
    )

    argparser.add_argument(
        "--skip-ssh", help="Turn off basic SSH validation", action="store_true"
    )

    argparser.add_argument(
        "--pause-for-deletion",
        help="Wait for user input before deletion",
        action="store_true",
    )

    argparser.add_argument(
        "--skip-deletion", help="Leave instance behind", action="store_true"
    )

    argparser.add_argument(
        "--virthost",
        default=None,
        help="Specify a particular host to launch on, e.g. labvirt1001.  Default"
        "behavior is to use the standard scheduling pool.",
    )

    argparser.add_argument(
        "--adhoc-command",
        default="",
        help="Specify a command over SSH prior to deletion",
    )

    argparser.add_argument(
        "--network", default="", help="Specify a Neutron network for VMs"
    )

    argparser.add_argument(
        "--statsd",
        default=None,
        help="Send statistics to statsd endpoint (default: statsd.<deployment>.wmnet)",
    )

    argparser.add_argument(
        "--deployment",
        default=Deployment.EQIAD1,
        choices=list(Deployment),
        type=Deployment,
        help="Openstack deployment to act on.",
    )
    args = argparser.parse_args()

    return args


def verify_args(args: argparse.Namespace) -> None:
    if args.adhoc_command and args.skip_ssh:
        LOGGER.error("cannot skip SSH with adhoc command specified")
        sys.exit(1)

    try:
        with open(args.keyfile, "r", encoding="utf-8") as keyfile_fd:
            keyfile_fd.read()
    except OSError:
        LOGGER.error("keyfile %s cannot be read", args.keyfile)
        sys.exit(1)

    password = os.environ.get("OS_PASSWORD")
    user = os.environ.get("OS_USERNAME") or args.user
    project = os.environ.get("OS_PROJECT_ID") or args.project
    if not all([user, password, project]):
        LOGGER.error("Set the username, password (only env var) and project.")
        sys.exit(1)


def setup_logging(debug: bool, vm_name: str) -> None:
    LOGGER.setLevel(logging.DEBUG if debug else logging.INFO)
    log_handler = logging.StreamHandler()
    log_formatter = ECSFormatter()
    log_handler.setFormatter(log_formatter)
    LOGGER.addHandler(log_handler)

    # Override sys.excepthook to pass unhandled exceptions to the logger
    sys.excepthook = log_unhandled_exception
    log_formatter.set_hostname(vm_name)


def get_new_vm_name(instance_prefix: str) -> str:
    date = int(datetime.today().strftime("%Y%m%d%H%M%S"))
    return f"{instance_prefix}-{date}"


@dataclass(frozen=True)
class NovaCliAuth:
    keystone_url: str
    user: str
    password: str
    project_name: str
    region_name: str

    @classmethod
    def from_env(
        cls, keystone_url: str, fallback_user: str, fallback_project: str
    ) -> "NovaCliAuth":
        password = os.environ.get("OS_PASSWORD")
        region_name = os.environ.get("OS_REGION_NAME")
        user = os.environ.get("OS_USERNAME") or fallback_user
        project_name = os.environ.get("OS_PROJECT_ID") or fallback_project
        return cls(
            keystone_url=keystone_url,
            user=user,
            password=password,
            project_name=project_name,
            region_name=region_name,
        )


def get_nova_cli(nova_auth: NovaCliAuth) -> NovaClient:
    keystone_auth = KeystonePassword(
        auth_url=nova_auth.keystone_url,
        username=nova_auth.user,
        password=nova_auth.password,
        user_domain_name="Default",
        project_domain_name="Default",
        project_name=nova_auth.project_name,
    )

    session = keystone_session.Session(auth=keystone_auth)
    # We specify 2.19 because that's the earliest version that supports
    # updating VM description
    return nova_client.Client(
        version="2.19", session=session, region_name=nova_auth.region_name
    )


def cleanup_leaked_vms(
    leaked_vms: List[Server], max_vms: int, instance_prefix: str
) -> None:
    """Make space for the current run.

    That is, delete VMs until max_vms - 1.
    """
    num_to_cleanup = len(leaked_vms) - (max_vms - 1)
    LOGGER.info(
        "There are %d (%d allowed) leaked instances with prefix %s",
        len(leaked_vms),
        max_vms,
        instance_prefix,
    )
    vms = sorted(leaked_vms, key=lambda server: server.human_id)
    if num_to_cleanup > 0:
        LOGGER.info(
            "Cleaning up %d VMs to make space for this run.",
            num_to_cleanup,
        )
        for vm in vms[:num_to_cleanup]:
            vm.delete()


def verify_vm_ipaddr(vm: Server) -> str:
    """Verifies that the address of the new VM is what we expect.

    Raises Exception when failed.

    Returns the server ipaddress.
    """
    if "public" in vm.addresses:
        addr = vm.addresses["public"][0]["addr"]
        if not addr.startswith("10."):
            raise Exception(f"Bad address of {addr}")
    else:
        addr = vm.addresses["lan-flat-cloudinstances2b"][0]["addr"]
        if not addr.startswith("172."):
            raise Exception(f"Bad address of {addr}")

    return addr


def main():
    args = get_args()

    instance_prefix = args.prepend
    new_vm_name = get_new_vm_name(instance_prefix)

    setup_logging(debug=args.debug, vm_name=new_vm_name)

    # After setting up the logging, chicken and egg issue
    verify_args(args)
    auth = NovaCliAuth.from_env(
        keystone_url=(
            args.keystone_url
            or f"https://openstack.{args.deployment}.wikimediacloud.org:25357/v3"
        ),
        fallback_user=args.user,
        fallback_project=args.project,
    )

    stat_handler = StatHandler(
        statsd_host=args.statsd or f"statsd.{args.deployment.to_wmnet()}.wmnet",
    )

    while True:
        loop_start = round(time.time(), 2)

        nova_cli = get_nova_cli(nova_auth=auth)

        all_vms: List[Server] = nova_cli.servers.list()
        LOGGER.debug(all_vms)

        leaked_vms = [
            server for server in all_vms if server.human_id.startswith(instance_prefix)
        ]
        stat_handler.add_stat("instances.count", len(leaked_vms))
        stat_handler.add_stat("instances.max", args.max_pool)

        if not args.preserve_leaks:
            cleanup_leaked_vms(
                leaked_vms=leaked_vms,
                max_vms=args.max_pool,
                instance_prefix=instance_prefix,
            )

        if len(leaked_vms) >= args.max_pool:
            # If the cleanup in the last two cycles didn't get us anywhere,
            #  best to just bail out so we stop trampling on the API.
            LOGGER.error(
                "max server(s) with prepend %s -- skipping creation", instance_prefix
            )
            continue

        new_vm_image: Image = nova_cli.glance.find_image(args.image)
        new_vm_flavor: Flavor = nova_cli.flavors.find(name=args.flavor)

        try:
            (verify_creation_time, new_vm) = verify_create(
                nova_connection=nova_cli,
                name=new_vm_name,
                image=new_vm_image,
                flavor=new_vm_flavor,
                timeout=args.creation_timeout,
                network=args.network,
                on_host=args.virthost,
            )
            stat_handler.add_stat("verify.creation", verify_creation_time)
            new_vm = new_vm.update(description="Running tests...")
            vm_fqdn = (
                f"{new_vm.name}.{new_vm.tenant_id}.{args.deployment}.wikimedia.cloud"
            )

            vm_addr = verify_vm_ipaddr(vm=new_vm)

            if not args.skip_dns:
                verify_dns_time = verify_dns(
                    hostname=vm_fqdn,
                    expected_ip=vm_addr,
                    nameservers=args.dns_resolvers,
                    timeout=60.0,
                )
                stat_handler.add_stat("verify.dns", verify_dns_time)

                verify_dns_reverse_time = verify_dns_reverse(
                    hostname=vm_fqdn,
                    ipaddr=vm_addr,
                    nameservers=args.dns_resolvers,
                    timeout=30.0,
                )
                stat_handler.add_stat("verify.dns-reverse", verify_dns_reverse_time)

            if not args.skip_ssh:
                verify_ssh_time = verify_ssh(
                    vm_addr, auth.user, args.keyfile, args.bastion_ip, args.ssh_timeout
                )

                stat_handler.add_stat("verify.ssh", verify_ssh_time)
                if args.adhoc_command:
                    command_stdout = run_remote(
                        node=vm_addr,
                        username=auth.user,
                        keyfile=args.keyfile,
                        bastion_ip=args.bastion_ip,
                        cmd=args.adhoc_command,
                        debug=args.debug,
                    )
                    LOGGER.debug(command_stdout)

            if not args.skip_puppet:
                (puppet_time, puppet_run_summary) = verify_puppet(
                    address=vm_addr,
                    user=auth.user,
                    keyfile=args.keyfile,
                    bastion_ip=args.bastion_ip,
                    timeout=args.puppet_timeout,
                )

                stat_handler.add_stat("verify.puppet", puppet_time)
                puppet_stats = ["changes", "events", "resources", "time"]
                for puppet_stat in puppet_stats:
                    for key, value in puppet_run_summary[puppet_stat].items():
                        stat_handler.add_stat(f"puppet.{puppet_stat}.{key}", value)

            if args.pause_for_deletion:
                LOGGER.info("Pausing for deletion")
                if not ask_confirmation("Continue with deletion?"):
                    print("Aborting on user input.")
                    sys.exit(0)

            if not args.skip_deletion:
                verify_deletion_time = verify_deletion(
                    nova_cli=nova_cli, vm=new_vm, timeout=args.deletion_timeout
                )

            if not args.pause_for_deletion:
                stat_handler.add_stat("verify.deletion", verify_deletion_time)
                loop_end = time.time()
                stat_handler.add_stat(
                    "verify.fullstack", round(loop_end - loop_start, 2)
                )

            if not args.skip_dns:
                verify_dns_time = verify_dns_cleanup(
                    hostname=vm_fqdn, nameservers=args.dns_resolvers, timeout=60.0
                )
                stat_handler.add_stat("verify.dns-cleanup", verify_dns_time)

                verify_dns_reverse_time = verify_dns_reverse_cleanup(
                    ipaddr=vm_addr, nameservers=args.dns_resolvers, timeout=60.0
                )
                stat_handler.add_stat(
                    "verify.dns-cleanup-reverse", verify_dns_reverse_time
                )

            if not args.interval:
                return

            stat_handler.add_stat("verify.success", 1)
        except Exception as error:
            LOGGER.exception("%s failed, leaking", new_vm_name)
            stat_handler.add_stat("verify.success", 0)
            try:
                # Update VM with a hint about why it leaked. Of course
                #  if things are truly broken this will also fail, so
                #  swallow any failures
                new_vm.update(description=str(error))
            except:  # noqa: E722
                LOGGER.warning("Failed to annotate VM with failure condition")
        finally:
            stat_handler.flush_stats()

        time.sleep(args.interval)


if __name__ == "__main__":
    main()
