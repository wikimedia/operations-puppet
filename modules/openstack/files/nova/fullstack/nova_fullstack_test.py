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
from keystoneauth1.identity.v3 import Password as KeystonePassword
from keystoneauth1 import session as keystone_session
import logging
import novaclient
from novaclient import client as nova_client
import os
import socket
import subprocess
import sys
import time
import yaml
from datetime import datetime


class Timer:
    def __init__(self):
        self.start = self.now()
        self.wait = 0

    def __enter__(self):
        self.__init__()
        return self

    def now(self):
        return round(time.time(), 2)

    def progress(self):
        return round(self.now() - self.start, 2)

    def close(self):
        self.wait = None
        self.end = self.now()
        self.interval = round(self.end - self.start, 2)

    def __exit__(self, *args):
        self.close()


class ECSFormatter(logging.Formatter):
    """ECS 1.7.0 logging formatter"""

    def __init__(self):
        self.hostname = ""

    def format(self, record):
        ecs_message = {
            "ecs.version": "1.7.0",
            "log.level": record.levelname.upper(),
            "log.origin.file.line": record.lineno,
            "log.origin.file.name": record.filename,
            "log.origin.file.path": record.pathname,
            "log.origin.function": record.funcName,
            "log.test.hostname": self.hostname,
            "message": str(record.msg),
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
        return "@cee: %s" % json.dumps(ecs_message)

    def set_hostname(self, hostname):
        self.hostname = hostname


def log_unhandled_exception(exc_type, exc_value, exc_traceback):
    """Forwards unhandled exceptions to log handler.  Override sys.excepthook to activate."""
    logging.exception(
        "Unhandled exception: %s" % exc_value,
        exc_info=(exc_type, exc_value, exc_traceback),
    )


def get_verify(prompt, invalid, valid):
    """ validate user inputed for expected
    """
    while True:
        try:
            inp = input("{} {}:".format(prompt, valid))
            if inp.lower() not in valid:
                raise ValueError(invalid)
        except ValueError:
            continue
        else:
            break


def run_remote(node, username, keyfile, bastion_ip, cmd, debug=False):
    """ Execute a remote command using SSH
    :param node: str
    :param cmd: str
    :param debug: bool
    :return: str
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
        "LogLevel={}".format("DEBUG" if debug else "ERROR"),
        "-o",
        'ProxyCommand="ssh -o StrictHostKeyChecking=no -i {} -W %h:%p {}@{}"'.format(
            keyfile, username, bastion_ip
        ),
        "-i",
        keyfile,
        "{}@{}".format(username, node),
    ]

    fullcmd = ssh + cmd.split(" ")
    logging.debug(" ".join(fullcmd))

    # The nested nature of the proxycommand line is baffling to
    #  subprocess and/or ssh; joining a full shell commandline
    #  works and gives us something we can actually test by hand.
    return subprocess.check_output(
        " ".join(fullcmd), shell=True, stderr=subprocess.STDOUT
    )


def run_local(cmd):
    """ Execute a remote command using SSH
    :param cmd: list
    :return: str
    """
    logging.debug(" ".join(cmd))
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT)


def verify_dns(hostname, expected_ip, nameservers, timeout=2.0):
    """ ensure dns resolution for the created VM
    :param hostame: str
    :param expected_ip: str
    :param nameservers: list
    :return: obj
    """
    with Timer() as ns:
        logging.info("Resolving {} from {}".format(hostname, nameservers))
        dig_query = []
        dig_query.append("/usr/bin/dig")
        for server in nameservers:
            dig_query.append("@{}".format(server))
        dig_query.append(hostname)
        dig_options = ["+short", "+time=2", "+tries=1"]

        while True:
            out = run_local(dig_query + dig_options)
            logging.debug(out)

            if out.decode("utf8").strip() == expected_ip.strip():
                # Success
                break

            if out:
                raise Exception(
                    "DNS failure: got the wrong IP {} for hostname {}; expected {}".format(
                        out.decode("utf8").strip(), hostname, expected_ip
                    )
                )

            # If we got here then dig returned an empty string which suggests NXDOMAIN.
            # wait and see if something shows up.
            dnswait = ns.progress()
            if dnswait >= timeout:
                raise Exception(
                    "Timed out waiting for A record for {}".format(hostname)
                )

            time.sleep(1)

    return ns.interval


def verify_dns_reverse(hostname, ip, nameservers, timeout=2.0):
    """ ensure reverse dns resolution for the created VM
    :param hostame: str
    :param nameservers: list
    :return: obj
    """
    with Timer() as ns:
        logging.info("Resolving {} from {}".format(ip, nameservers))
        dig_query = []
        dig_query.append("/usr/bin/dig")
        for server in nameservers:
            dig_query.append("@{}".format(server))
        dig_query.append("-x")
        dig_query.append(ip)
        dig_options = ["+short", "+time=2", "+tries=1"]

        while True:
            out = run_local(dig_query + dig_options)
            logging.debug(out)

            if out.decode("utf8").strip().strip(".") == hostname.strip():
                # Success
                break

            if out:
                raise Exception(
                    "DNS -x failure: got the wrong hostname {} for ip {}; expected {}".format(
                        out.decode("utf8").strip(), ip, hostname
                    )
                )

            # If we got here then dig returned an empty string which suggests NXDOMAIN.
            # wait and see if something shows up.
            dnswait = ns.progress()
            if dnswait >= timeout:
                raise Exception("Timed out waiting for ptr record for {}".format(ip))

            time.sleep(1)

    return ns.interval


def verify_dns_cleanup(hostname, nameservers, timeout=2.0):
    """ ensure the DNS entry was cleared
    :param hostame: str
    :param nameservers: list
    :return: obj
    """
    with Timer() as ns:
        logging.info(
            "Resolving {} from {}, waiting for cleanup".format(hostname, nameservers)
        )
        while True:
            time.sleep(10)
            dig_query = []
            dig_query.append("/usr/bin/dig")
            for server in nameservers:
                dig_query.append("@{}".format(server))
            dig_query.append(hostname)
            dig_options = ["+short", "+time=2", "+tries=1"]
            out = run_local(dig_query + dig_options)
            if not out:
                break
            dnscleanupwait = ns.progress()
            if dnscleanupwait >= timeout:
                raise Exception("Failed to clean up dns for {}".format(hostname))
    return ns.interval


def verify_dns_reverse_cleanup(ip, nameservers, timeout=2.0):
    """ ensure the DNS entry was cleared
    :param ip: str
    :param nameservers: list
    :return: obj
    """
    with Timer() as ns:
        logging.info(
            "Resolving {} from {}, waiting for cleanup".format(ip, nameservers)
        )
        while True:
            time.sleep(10)
            dig_query = []
            dig_query.append("/usr/bin/dig")
            for server in nameservers:
                dig_query.append("@{}".format(server))
            dig_query.append("-x")
            dig_query.append(ip)
            dig_options = ["+short", "+time=2", "+tries=1"]
            out = run_local(dig_query + dig_options)
            if not out:
                break
            dnscleanupwait = ns.progress()
            if dnscleanupwait >= timeout:
                raise Exception("Failed to clean up dns ptr record for {}".format(ip))
    return ns.interval


def verify_ssh(address, user, keyfile, bastion_ip, timeout):
    """ ensure SSH works to an instance
    :param address: str
    :param timeout: int
    :return: float
    """
    with Timer() as vs:
        logging.info("SSH to {}".format(address))
        while True:
            time.sleep(10)
            try:
                run_remote(address, user, keyfile, bastion_ip, "/bin/true")
                break
            except subprocess.CalledProcessError as e:
                logging.debug(e)
                logging.debug("SSH wait for {}".format(vs.progress()))

            sshwait = vs.progress()
            if sshwait >= timeout:
                raise Exception("SSH for {} timed out".format(address))
    return vs.interval


def verify_puppet(address, user, keyfile, bastion_ip, timeout):
    """ Ensure Puppet has run on an instance
    :param address: str
    :param timeout: init
    :return: float, dict
    """
    with Timer() as pv:
        logging.info("Verify Puppet run on {}".format(address))
        while True:
            out = "No command run yet"
            try:
                cp = "sudo cat /var/lib/puppet/state/last_run_summary.yaml"
                out = run_remote(address, user, keyfile, bastion_ip, cp)
                break
            except subprocess.CalledProcessError as e:
                logging.debug(e)
                logging.debug(e.stdout)
                out = e.stdout
                logging.debug("Puppet wait {}".format(pv.progress()))

            pwait = pv.progress()
            if pwait > timeout:
                raise Exception(
                    "Timed out trying to verify puppet for {}, last check run output: {}".format(
                        address, out
                    )
                )
            time.sleep(10)

    logging.debug(out)
    try:
        yprun = yaml.safe_load(out)
    except yaml.YAMLError:
        logging.warning("Yaml conversion failed for Puppet results")
        yprun = {}

    logging.debug(yprun)
    return pv.interval, yprun


def verify_create(nova_connection, name, image, flavor, timeout, network, on_host=None):
    """ Create and ensure creation for an instance
    :param nova_connection: nova connection obj
    :param name: str
    :param image: image obj
    :param flavor: flavor obj
    :param timeout: int
    :return: float, obj
    """

    with Timer() as vc:
        logging.info("Creating {}".format(name))
        if on_host:
            availability_zone = "server:{}".format(on_host)
        else:
            availability_zone = None

        if network:
            nics = [{"net-id": network}]
        else:
            nics = None

        cserver = nova_connection.servers.create(
            name=name,
            image=image.id,
            flavor=flavor.id,
            nics=nics,
            availability_zone=availability_zone,
        )
        while True:
            server = nova_connection.servers.get(cserver.id)
            if server.status == "ACTIVE":
                break
            cwait = vc.progress()
            logging.debug("creation at {}s".format(cwait))
            if cwait > timeout:
                raise Exception("creation of {} timed out".format(cserver.id))
            time.sleep(10)
    return vc.interval, server


def verify_deletion(nova_connection, server, timeout):
    """ Delete and ensure deletion of an instance
    :param nova_connection: nova connection obj
    :param server: nova server obj
    :param timeout: int
    :return: float
    """

    with Timer() as dw:
        logging.info("Removing {}".format(server.human_id))
        server.delete()
        while True:
            try:
                nova_connection.servers.get(server.id)
            except novaclient.exceptions.NotFound:
                logging.info("{} succesfully removed".format(server.human_id))
                break

            dwait = dw.progress()
            if dwait > timeout:
                raise Exception("{} deletion timed out".format(server.human_id))
            time.sleep(30)
    return dw.interval


def submit_stat(host, port, prepend, metric, value):
    """ Metric handling for tracking over time
    :param host: str
    :param port: int
    :param prepend: str
    :param metric: str
    :param value: int
    """
    fmetric = "{}.{}".format(prepend, metric)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    s.connect((host, port))
    s.send("{}:{}|g".format(fmetric, value).encode("utf8"))
    logging.info("{} => {} {}".format(fmetric, value, int(time.time())))


def main():

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
        default=120,
        type=int,
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
        default="208.80.154.143,208.80.154.24",
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
        default="statsd.eqiad.wmnet",
        help="Send statistics to statsd endpoint",
    )

    args = argparser.parse_args()

    # Override sys.excepthook to pass unhandled exceptions to the logger
    sys.excepthook = log_unhandled_exception

    # Set up logging
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG if args.debug else logging.INFO)
    logHandler = logging.StreamHandler()
    logformatter = ECSFormatter()
    logHandler.setFormatter(logformatter)
    logger.addHandler(logHandler)

    if args.adhoc_command and args.skip_ssh:
        logging.error("cannot skip SSH with adhoc command specified")
        sys.exit(1)

    try:
        with open(args.keyfile, "r") as f:
            f.read()
    except OSError:
        logging.error("keyfile {} cannot be read".format(args.keyfile))
        sys.exit(1)

    pw = os.environ.get("OS_PASSWORD")
    region = os.environ.get("OS_REGION_NAME")
    user = os.environ.get("OS_USERNAME") or args.user
    project = os.environ.get("OS_PROJECT_ID") or args.project
    if not all([user, pw, project]):
        logging.error("Set username and password environment variables")
        sys.exit(1)

    def stat(metric, value):
        metric_prepend = "cloudvps.novafullstack.{}".format(socket.gethostname())
        submit_stat(args.statsd, 8125, metric_prepend, metric, value)

    while True:

        loop_start = round(time.time(), 2)

        auth = KeystonePassword(
            auth_url=args.keystone_url,
            username=user,
            password=pw,
            user_domain_name="Default",
            project_domain_name="Default",
            project_name=project,
        )

        sess = keystone_session.Session(auth=auth)
        # We specify 2.19 because that's the earliest version that supports
        # updating VM description
        nova_conn = nova_client.Client("2.19", session=sess, region_name=region)

        prepend = args.prepend
        date = int(datetime.today().strftime("%Y%m%d%H%M%S"))
        name = "{}-{}".format(prepend, date)
        logformatter.set_hostname(name)

        exist = nova_conn.servers.list()
        logging.debug(exist)
        prependinstances = [
            server for server in exist if server.human_id.startswith(prepend)
        ]
        pexist_count = len(prependinstances)

        stat("instances.count", pexist_count)
        stat("instances.max", args.max_pool)

        # If we're pushing up against max_pool, delete the oldest server
        if not args.preserve_leaks and pexist_count >= args.max_pool - 1:
            logging.warning(
                "There are {} leaked instances with prepend {}; "
                "cleaning up".format(pexist_count, prepend)
            )
            servers = sorted(prependinstances, key=lambda server: server.human_id)
            servers[0].delete()

        if pexist_count >= args.max_pool:
            # If the cleanup in the last two cycles didn't get us anywhere,
            #  best to just bail out so we stop trampling on the API.
            logging.error(
                "max server(s) with prepend {} -- skipping creation".format(prepend)
            )
            continue

        cimage = nova_conn.glance.find_image(args.image)
        cflavor = nova_conn.flavors.find(name=args.flavor)

        try:
            vc, server = verify_create(
                nova_conn,
                name,
                cimage,
                cflavor,
                args.creation_timeout,
                args.network,
                args.virthost,
            )
            stat("verify.creation", vc)
            server.update(description="Running tests...")

            if "public" in server.addresses:
                addr = server.addresses["public"][0]["addr"]
                if not addr.startswith("10."):
                    raise Exception("Bad address of {}".format(addr))
            else:
                addr = server.addresses["lan-flat-cloudinstances2b"][0]["addr"]
                if not addr.startswith("172."):
                    raise Exception("Bad address of {}".format(addr))

            if not args.skip_dns:
                host = "{}.{}.eqiad1.wikimedia.cloud".format(
                    server.name, server.tenant_id
                )
                dnsd = args.dns_resolvers.split(",")
                vdns = verify_dns(host, addr, dnsd, timeout=30)
                stat("verify.dns", vdns)
                vdns_reverse = verify_dns_reverse(host, addr, dnsd, timeout=30)
                stat("verify.dns-reverse", vdns_reverse)

            if not args.skip_ssh:
                vs = verify_ssh(
                    addr, user, args.keyfile, args.bastion_ip, args.ssh_timeout
                )

                stat("verify.ssh", vs)
                if args.adhoc_command:
                    sshout = run_remote(
                        addr,
                        user,
                        args.keyfile,
                        args.bastion_ip,
                        args.adhoc_command,
                        debug=args.debug,
                    )
                    logging.debug(sshout)

            if not args.skip_puppet:
                ps, puppetrun = verify_puppet(
                    addr, user, args.keyfile, args.bastion_ip, args.puppet_timeout
                )
                stat("verify.puppet", ps)

                categories = ["changes", "events", "resources", "time"]

                for d in categories:
                    for k, v in puppetrun[d].items():
                        stat("puppet.{}.{}".format(d, k), v)

            if args.pause_for_deletion:
                logging.info("Pausing for deletion")
                get_verify("continue with deletion", "Not a valid response", ["y"])

            if not args.skip_deletion:
                vd = verify_deletion(nova_conn, server, args.deletion_timeout)

            if not args.pause_for_deletion:
                stat("verify.deletion", vd)
                loop_end = time.time()
                stat("verify.fullstack", round(loop_end - loop_start, 2))

            if not args.skip_dns:
                host = "{}.{}.eqiad1.wikimedia.cloud".format(
                    server.name, server.tenant_id
                )
                dnsd = args.dns_resolvers.split(",")
                vdns = verify_dns_cleanup(host, dnsd, timeout=60.0)
                stat("verify.dns-cleanup", vdns)
                vdns_reverse = verify_dns_reverse_cleanup(addr, dnsd, timeout=60.0)
                stat("verify.dns-cleanup-reverse", vdns_reverse)

            if not args.interval:
                return

            stat("verify.success", 1)
        except Exception as e:
            logging.exception("{} failed, leaking".format(name))
            stat("verify.success", 0)
            try:
                # Update VM with a hint about why it leaked. Of course
                #  if things are truly broken this will also fail, so
                #  swallow any failures
                server.update(description=str(e))
            except:  # noqa: E722
                logging.warning("Failed to annotate VM with failure condition")

        time.sleep(args.interval)


if __name__ == "__main__":
    main()
