#!/usr/bin/env python3
"""
Full stack instance life cycle testing.  Meant to be run
as a daemon and then also adhoc for testing.

Guidelines for verification phases:
- Phases are independent as much as possible
- Wrapped with a Timer object
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
from datetime import datetime
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


class Timer:
    def __init__(self):
        self.start = 0.0
        self.wait = 0.0
        self.end = 0.0
        self.interval = 0.0

    def __enter__(self) -> "Timer":
        self.do_start()
        return self

    def do_start(self) -> None:
        self.start = self.now()
        self.wait = 0.0

    def now(self) -> float:
        return round(time.time(), 2)

    def progress(self) -> float:
        return round(self.now() - self.start, 2)

    def close(self) -> None:
        self.wait = None
        self.end = self.now()
        self.interval = round(self.end - self.start, 2)

    def __exit__(self, *args) -> None:
        self.close()


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


def get_verify(prompt: str, invalid: str, valid: List[str]) -> None:
    """validate user input for expected."""
    while True:
        try:
            inp = input(f"{prompt} {valid}:")
            if inp.lower() not in valid:
                # TODO: this seems like not used anywhere, any reason not to just loop until valid
                # instead?
                raise ValueError(invalid)
        except ValueError:
            continue
        else:
            break


def run_remote(
    node: str,
    username: str,
    keyfile: str,
    bastion_ip: str,
    cmd: str,
    debug: bool = False,
) -> bytes:
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

    fullcmd = ssh + cmd.split(" ")
    LOGGER.debug(" ".join(fullcmd))

    # The nested nature of the proxycommand line is baffling to
    #  subprocess and/or ssh; joining a full shell commandline
    #  works and gives us something we can actually test by hand.
    return subprocess.check_output(" ".join(fullcmd), shell=True, stderr=subprocess.STDOUT)


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
    with Timer() as ns_timer:
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
            dnswait = ns_timer.progress()
            if dnswait >= timeout:
                raise Exception(f"Timed out waiting for A record for {hostname}")

            time.sleep(1)

    return ns_timer.interval


def verify_dns_reverse(
    hostname: str, ipaddr: str, nameservers: List[str], timeout: float = 2.0
) -> float:
    """Ensure reverse dns resolution for the created VM.

    Return the time it took to run.
    """
    with Timer() as ns_timer:
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
            dnswait = ns_timer.progress()
            if dnswait >= timeout:
                raise Exception(f"Timed out waiting for ptr record for {ipaddr}")

            time.sleep(1)

    return ns_timer.interval


def verify_dns_cleanup(hostname: str, nameservers: List[str], timeout: float = 2.0) -> float:
    """Ensure the DNS entry was cleared.

    Return the time it took to run.
    """
    with Timer() as ns_timer:
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
            dnscleanupwait = ns_timer.progress()
            if dnscleanupwait >= timeout:
                raise Exception(f"Failed to clean up dns for {hostname}")
    return ns_timer.interval


def verify_dns_reverse_cleanup(ipaddr: str, nameservers: List[str], timeout: float = 2.0) -> float:
    """Ensure the DNS entry was cleared

    Return the time it took to run.
    """
    with Timer() as ns:
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
            dnscleanupwait = ns.progress()
            if dnscleanupwait >= timeout:
                raise Exception(f"Failed to clean up dns ptr record for {ipaddr}")
    return ns.interval


def verify_ssh(address: str, user: str, keyfile: str, bastion_ip: str, timeout: int) -> float:
    """Ensure SSH works to an instance.

    Returns the time it took to run.
    """
    with Timer() as timer:
        LOGGER.info("SSH to %s", address)
        while True:
            time.sleep(10)
            try:
                run_remote(address, user, keyfile, bastion_ip, "/bin/true")
                break
            except subprocess.CalledProcessError as error:
                LOGGER.debug(error)
                LOGGER.debug("SSH wait for %d", timer.progress())

            sshwait = timer.progress()
            if sshwait >= timeout:
                raise Exception(f"SSH for {address} timed out")
    return timer.interval


def verify_puppet(
    address: str, user: str, keyfile: str, bastion_ip: str, timeout: int
) -> Tuple[float, Dict[str, Any]]:
    """Ensure Puppet has run on an instance.

    Returns the elapsed time, and the puppet run summary.
    """
    with Timer() as timer:
        LOGGER.info("Verify Puppet run on %s", address)
        while True:
            out = "No command run yet"
            try:
                cp = "sudo cat /var/lib/puppet/state/last_run_summary.yaml"
                out = run_remote(address, user, keyfile, bastion_ip, cp).decode("utf-8")
                break
            except subprocess.CalledProcessError as error:
                LOGGER.debug(error)
                LOGGER.debug(error.stdout)
                out = error.stdout
                LOGGER.debug("Puppet wait %d", timer.progress())

            pwait = timer.progress()
            if pwait > timeout:
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
    return (timer.interval, last_run_summary)


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

    with Timer() as timer:
        LOGGER.info("Creating %s", name)
        if on_host:
            availability_zone = f"server:{on_host}"
        else:
            availability_zone = None

        if network:
            nics = [{"net-id": network}]
        else:
            nics = None

        cserver: Server = nova_connection.servers.create(
            name=name,
            image=image.id,
            flavor=flavor.id,
            nics=nics,
            availability_zone=availability_zone,
        )
        while True:
            server: Server = nova_connection.servers.get(cserver.id)
            if server.status == "ACTIVE":
                break
            cwait = timer.progress()
            LOGGER.debug("creation at %ds", cwait)
            if cwait > timeout:
                raise Exception(f"creation of {cserver.id} timed out")
            time.sleep(10)
    return timer.interval, server


def verify_deletion(nova_connection: NovaClient, server: Server, timeout: float) -> float:
    """Delete and ensure deletion of an instance."""

    with Timer() as timer:
        LOGGER.info("Removing %s", server.human_id)
        server.delete()
        while True:
            try:
                nova_connection.servers.get(server.id)
            except novaclient.exceptions.NotFound:
                LOGGER.info("%s successfully removed", server.human_id)
                break

            dwait = timer.progress()
            if dwait > timeout:
                raise Exception("{server.human_id} deletion timed out")
            time.sleep(30)
    return timer.interval


def submit_stat(host: str, port: int, prepend: str, metric: str, value: Union[int, float]) -> None:
    """Metric handling for tracking over time."""
    metric_path = f"{prepend}.{metric}"
    my_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    my_socket.connect((host, port))
    my_socket.send(f"{metric_path}:{value}|g".encode("utf8"))
    LOGGER.info("%s => %f %d", metric_path, value, int(time.time()))


def main():

    argparser = argparse.ArgumentParser()

    argparser.add_argument("--debug", help="Turn on debug logging", action="store_true")

    argparser.add_argument(
        "--project", default="admin-monitoring", help="Set project to test creation for"
    )

    argparser.add_argument("--keyfile", default="", help="Path to SSH key file for verification")

    argparser.add_argument("--bastion-ip", default="", help="IP of bastion to use for ssh tests")

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

    argparser.add_argument("--max-pool", default=1, type=int, help="Allow this many instances")

    argparser.add_argument("--preserve-leaks", help="Never delete failed VMs", action="store_true")

    argparser.add_argument(
        "--keystone-url",
        default="https://openstack.eqiad1.wikimediacloud.org:25357/v3",
        help="Auth url for token and service discovery",
    )

    argparser.add_argument(
        "--interval",
        default=600,
        type=int,
        help="Seconds delay for daemon (default: 600 [10m])",
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

    argparser.add_argument("--skip-puppet", help="Turn off Puppet validation", action="store_true")

    argparser.add_argument("--skip-dns", help="Turn off DNS validation", action="store_true")

    argparser.add_argument(
        "--dns-resolvers",
        help="Comma separated list of nameservers",
        default="208.80.154.143,208.80.154.24",
    )

    argparser.add_argument("--skip-ssh", help="Turn off basic SSH validation", action="store_true")

    argparser.add_argument(
        "--pause-for-deletion",
        help="Wait for user input before deletion",
        action="store_true",
    )

    argparser.add_argument("--skip-deletion", help="Leave instance behind", action="store_true")

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

    argparser.add_argument("--network", default="", help="Specify a Neutron network for VMs")

    argparser.add_argument(
        "--statsd",
        default="statsd.eqiad.wmnet",
        help="Send statistics to statsd endpoint",
    )

    args = argparser.parse_args()

    # Override sys.excepthook to pass unhandled exceptions to the logger
    sys.excepthook = log_unhandled_exception

    # Set up logging
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG if args.debug else LOGGER.info)
    log_handler = logging.StreamHandler()
    log_formatter = ECSFormatter()
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)

    if args.adhoc_command and args.skip_ssh:
        logging.error("cannot skip SSH with adhoc command specified")
        sys.exit(1)

    try:
        with open(args.keyfile, "r", encoding="utf-8") as keyfile_fd:
            keyfile_fd.read()
    except OSError:
        logging.error("keyfile %s cannot be read", args.keyfile)
        sys.exit(1)

    password = os.environ.get("OS_PASSWORD")
    region = os.environ.get("OS_REGION_NAME")
    user = os.environ.get("OS_USERNAME") or args.user
    project = os.environ.get("OS_PROJECT_ID") or args.project
    if not all([user, password, project]):
        LOGGER.error("Set the username, password (only env var) and project.")
        sys.exit(1)

    def stat(metric: str, value: Union[int, float]) -> None:
        metric_prepend = f"cloudvps.novafullstack.{socket.gethostname()}"
        submit_stat(args.statsd, 8125, metric_prepend, metric, value)

    while True:

        loop_start = round(time.time(), 2)

        auth = KeystonePassword(
            auth_url=args.keystone_url,
            username=user,
            password=password,
            user_domain_name="Default",
            project_domain_name="Default",
            project_name=project,
        )

        session = keystone_session.Session(auth=auth)
        # We specify 2.19 because that's the earliest version that supports
        # updating VM description
        nova_conn: NovaClient = nova_client.Client("2.19", session=session, region_name=region)

        instance_prefix = args.prepend
        date = int(datetime.today().strftime("%Y%m%d%H%M%S"))
        name = f"{instance_prefix}-{date}"
        log_formatter.set_hostname(name)

        exist: List[Server] = nova_conn.servers.list()
        LOGGER.debug(exist)
        existing_instances = [
            server for server in exist if server.human_id.startswith(instance_prefix)
        ]
        pexist_count = len(existing_instances)

        stat("instances.count", pexist_count)
        stat("instances.max", args.max_pool)

        # If we're pushing up against max_pool, delete the oldest server
        if not args.preserve_leaks and pexist_count >= args.max_pool - 1:
            LOGGER.warning(
                "There are %d leaked instances with prepend %s; cleaning up",
                pexist_count,
                instance_prefix,
            )
            servers = sorted(existing_instances, key=lambda server: server.human_id)
            servers[0].delete()

        if pexist_count >= args.max_pool:
            # If the cleanup in the last two cycles didn't get us anywhere,
            #  best to just bail out so we stop trampling on the API.
            logging.error("max server(s) with prepend %s -- skipping creation", instance_prefix)
            continue

        cimage: Image = nova_conn.glance.find_image(args.image)
        cflavor: Flavor = nova_conn.flavors.find(name=args.flavor)

        try:
            verify_creation_time, server = verify_create(
                nova_conn,
                name,
                cimage,
                cflavor,
                args.creation_timeout,
                args.network,
                args.virthost,
            )
            stat("verify.creation", verify_creation_time)
            server.update(description="Running tests...")

            if "public" in server.addresses:
                addr = server.addresses["public"][0]["addr"]
                if not addr.startswith("10."):
                    raise Exception(f"Bad address of {addr}")
            else:
                addr = server.addresses["lan-flat-cloudinstances2b"][0]["addr"]
                if not addr.startswith("172."):
                    raise Exception(f"Bad address of {addr}")

            if not args.skip_dns:
                host = f"{server.name}.{server.tenant_id}.eqiad1.wikimedia.cloud"
                nameservers = args.dns_resolvers.split(",")
                verify_dns_time = verify_dns(host, addr, nameservers, timeout=60.0)
                stat("verify.dns", verify_dns_time)
                verify_dns_reverse_time = verify_dns_reverse(host, addr, nameservers, timeout=30.0)
                stat("verify.dns-reverse", verify_dns_reverse_time)

            if not args.skip_ssh:
                verify_ssh_time = verify_ssh(
                    addr, user, args.keyfile, args.bastion_ip, args.ssh_timeout
                )

                stat("verify.ssh", verify_ssh_time)
                if args.adhoc_command:
                    sshout = run_remote(
                        addr,
                        user,
                        args.keyfile,
                        args.bastion_ip,
                        args.adhoc_command,
                        debug=args.debug,
                    )
                    LOGGER.debug(sshout)

            if not args.skip_puppet:
                puppet_time, puppet_run_summary = verify_puppet(
                    addr, user, args.keyfile, args.bastion_ip, args.puppet_timeout
                )
                stat("verify.puppet", puppet_time)

                categories = ["changes", "events", "resources", "time"]

                for category in categories:
                    for key, value in puppet_run_summary[category].items():
                        stat(f"puppet.{category}.{key}", value)

            if args.pause_for_deletion:
                LOGGER.info("Pausing for deletion")
                get_verify("continue with deletion", "Not a valid response", ["y"])

            if not args.skip_deletion:
                verify_deletion_time = verify_deletion(nova_conn, server, args.deletion_timeout)

            if not args.pause_for_deletion:
                stat("verify.deletion", verify_deletion_time)
                loop_end = time.time()
                stat("verify.fullstack", round(loop_end - loop_start, 2))

            if not args.skip_dns:
                host = f"{server.name}.{server.tenant_id}.eqiad1.wikimedia.cloud"
                nameservers = args.dns_resolvers.split(",")
                verify_dns_time = verify_dns_cleanup(host, nameservers, timeout=60.0)
                stat("verify.dns-cleanup", verify_dns_time)
                verify_dns_reverse_time = verify_dns_reverse_cleanup(
                    ipaddr=addr, nameservers=nameservers, timeout=60.0
                )
                stat("verify.dns-cleanup-reverse", verify_dns_reverse_time)

            if not args.interval:
                return

            stat("verify.success", 1)
        except Exception as error:
            LOGGER.exception("%s failed, leaking", name)
            stat("verify.success", 0)
            try:
                # Update VM with a hint about why it leaked. Of course
                #  if things are truly broken this will also fail, so
                #  swallow any failures
                server.update(description=str(error))
            except:  # noqa: E722
                LOGGER.warning("Failed to annotate VM with failure condition")

        time.sleep(args.interval)


if __name__ == "__main__":
    main()
