#!/usr/bin/python3
import argparse
import logging
import re
import shlex
import socket
import subprocess
import sys
import time
from urllib import parse

import requests
import yaml

# Optional poolcounter support
try:
    import poolcounter
    from poolcounter.client import RequestType

    pc_support = True
except ImportError:
    pc_support = False

from conftool.cli.tool import ToolCliBase
from conftool.drivers import BackendError

logger = logging.getLogger("service_restarter")


class PoolEntity:
    def __init__(self, name, *, cluster="", service="", port=0, servers=None):
        # Name is the name of the LVS pool.
        # It's one of the keys of profile::lvs::realserver::pools
        self.name = name
        self.cluster = cluster
        self.service = service
        self.port = port
        self.servers = servers

    @property
    def urls(self):
        """Returns the urls to check on pybal"""
        return ["http://{}:9090/pools/{}_{}".format(h, self.name, self.port) for h in self.servers]

    def matches(self, obj):
        """Checks if a conftool object represents this entity"""
        return (self.cluster == obj.tags['cluster'] and self.service == obj.tags['service'])


class PoolCollection:
    def __init__(self, pool_names, filename):
        # Read the collection of pools from a yaml file.
        # The file will be a yaml dictionary of pool name -> pool entity fields:
        # some-pool:
        #  cluster: a-conftool-cluster-tag
        #  service: a-conftool-service-tag
        #  port: 1234
        #  servers: [ lvs1, lvs2, lvs3]
        # some-other-pool: ...
        #
        self._collection = set()
        with open(filename, 'r') as fh:
            data = yaml.safe_load(fh)
        for name, pool_data in data.items():
            if name in pool_names:
                self._collection.add(PoolEntity(name, **pool_data))

    def filter(self, objects):
        """Get the pool entities corresponding to a list of conftool objects"""
        results = set()

        for el in self._collection:
            for obj in objects:
                if el.matches(obj):
                    results.add(el)
        return list(results)

    @property
    def services(self):
        """Return all conftool services in the selected pools"""
        return [el.service for el in self._collection]

    @property
    def names(self):
        return [el.name for el in self._collection]

    def all_urls(self):
        """Return all pybal urls to check for the selected pools"""
        all_urls = set()
        for el in self._collection:
            for url in el.urls:
                all_urls.add(url)
        return list(all_urls)


class ServiceRestarter(ToolCliBase):

    # Default error return-code from the script itself
    DEFAULT_RC = 127
    # poolcounter namespace
    POOLCOUNTER_NS = "ServiceRestarter"

    def __init__(self, args):
        super().__init__(args)
        self.fqdn = socket.getfqdn()
        self.retries = args.retries
        self.wait = args.wait
        self.pools = PoolCollection(args.pools, args.catalog)
        self.services = args.services
        self.timeout = args.timeout
        self.grace_period = args.grace_period
        self.force = args.force

    def announce(self):
        pass

    def _run_action(self):
        pass

    def _get_datacenter(self):
        try:
            with open("/etc/wikimedia-cluster") as fh:
                key = fh.read().strip()
            return key
        except FileNotFoundError:
            return "default"

    def get_poolcounter_key(self):
        """
        Returns the poolcounter key for this restart.
        """
        # The key will be composed as follows:
        # {POOLCOUNTER_NS}::datacenter::pool1-pool2...
        # pools will be ordered alphabetically
        return "{ns}::{dc}::{key}".format(
            ns=self.POOLCOUNTER_NS,
            dc=self._get_datacenter(),
            key="-".join(sorted(self.pools.names)),
        )

    def run_and_raise(self):
        """Restart the service, raise an exception if failed."""
        # ServiceRestarter.run returns an integer, while
        # poolcounter.client.Client run will only report an
        # error if the callback raises an exception.
        # So write a simple wrapper that will raise an exception on non-zero
        # exit code, so that the systemd timer will fail, and monitoring will
        # notice.
        rc = self.run()
        if rc != 0:
            raise RuntimeError("Failed executing ServiceRunner.run, return code %d", rc)

    def run(self):
        """
        Finds if a service for a host is pooled or not.
        """
        if self.force:
            logger.info("Restarting services without depool/repool")
            return self._restart_services()

        pooled = self._get_objects()
        if not pooled:
            logger.info(
                "The server is depooled from all services. Restarting the service directly"
            )
            # Everything is depooled, we can just restart the services
            return self._restart_services()

        logger.info("Depooling currently pooled services")
        if not self.depool(pooled):
            return self.DEFAULT_RC
        if self.grace_period > 0:
            logger.info(
                "Waiting %d seconds before restarting the service...", self.grace_period
            )
            time.sleep(self.grace_period)
        logger.info("Restarting the service")
        rc = self._restart_services()
        # If the restart fails, we don't really want to repool.
        if rc != 0:
            logger.warning("Service restart failed. NOT repooling")
            return rc
        logger.info("Repooling previously pooled services")
        if not self.pool(pooled):
            return self.DEFAULT_RC
        return rc

    def run_depool(self):
        """
        Only depools a service if it is pooled
        """
        pooled = self._get_objects("yes")
        logger.info("Depooling currently pooled services")
        if not pooled:
            logger.info("Services already depooled")
        elif not self.depool(pooled):
            logger.warning("Service depool failed.")
            return self.DEFAULT_RC

        return 0

    def run_pool(self):
        """
        Only depools a service if it is depooled (NOT inactive)
        """
        depooled = self._get_objects("no")
        logger.info("Pooling currently depooled services")
        if not depooled:
            logger.info("No service to pool.")
        elif not self.pool(depooled):
            logger.warning("Service pool failed.")
            return self.DEFAULT_RC

        return 0

    def _restart_services(self):
        rc = 0
        for svc in self.services:
            cmd = ["systemctl", "restart", svc + ".service"]
            cmd_str = " ".join(map(shlex.quote, cmd))
            try:
                subprocess.check_call(cmd)
                logger.debug("Execution of command %s successful", cmd_str)
            except subprocess.CalledProcessError as e:
                logger.error("Executing command %s failed: %s", cmd_str, e)
                rc = e.returncode
        return rc

    def _get_objects(self, pooled_state="yes"):
        """Gets the objects corresponding to the services we're operating on"""
        selector = {
            "service": re.compile("|".join(self.pools.services)),
            "name": re.compile(self.fqdn),
            "dc": re.compile(self._get_datacenter())
        }
        objects = list(self.entity.query(selector))
        pooled = [o for o in objects if o.pooled == pooled_state]
        return pooled

    def depool(self, pooled):
        """Depool a list of services"""
        try:
            # First let's depool in etcd
            for obj in pooled:
                obj.update({"pooled": "no"})
            # now let's wait for the services to be depooled in pybal
            self._verify_status(False, pooled)
            return True
        except (BackendError, PoolStatusError) as e:
            logger.error("Error depooling the servers: %s", e)
            return False

    def pool(self, pooled):
        """Pool a list of services"""
        try:
            for obj in pooled:
                obj.update({"pooled": "yes"})
            self._verify_status(True, pooled)
            return True
        except (BackendError, PoolStatusError) as e:
            logger.error("Error depooling the servers: %s", e)
            return False

    def _verify_status(self, want_pooled, pooled):
        # We only want to verify the status of objects that we're acting upon.
        if want_pooled:
            desired_status = "enabled/up/pooled"
        else:
            desired_status = "disabled/*/not pooled"
        for pool in self.pools.filter(pooled):
            for baseurl in pool.urls:
                url = "{baseurl}/{fqdn}".format(baseurl=baseurl, fqdn=self.fqdn)
                # This will raise a PoolStatusError
                logger.debug("Now verifying %s", url)
                self._fetch_retry(url, want_pooled, desired_status)

    def _fetch_retry(self, url, want_pooled, desired_status):
        headers = {
            "user-agent": "service-restarter/0.0.1",
            "accept": "application/json",
        }
        parsed = parse.urlparse(url)
        status = None
        for _ in range(0, self.retries):
            try:
                logger.debug("Fetching url %s", url)
                r = requests.get(url, headers=headers, timeout=self.timeout)
                r.raise_for_status()
            except requests.exceptions.HTTPError:
                # If we don't get a valid response, we bail out of checking.
                # This will account for servers that are inactive (which will
                # return 404) and for backing off if pybal is unable to respond
                # (5xx errors)
                logger.debug(
                    "Invalid response (status code %s) for %s - aborting",
                    r.status_code,
                    url,
                )
                return
            except requests.exceptions.Timeout:
                # In this case, we don't want to stampede pybal, we bail out
                logger.warning("Timed out checking %s", url)
                return
            except requests.exceptions.RequestException as e:
                logger.warning("Issues connecting to %s: %s", parsed.netloc, e)
                # For such errors, we just retry again
                continue

            # Now let's parse the response
            try:
                status = PoolStatus(**r.json())
            except Exception as e:
                logger.warning("Malformed response from the LB: %s", e)
                # Malformed response. We bail out as well
                return

            if status.has_state(want_pooled):
                logger.debug(
                    "OK - LB %s reports pool %s as %s",
                    parsed.netloc,
                    parsed.path.replace("/pools/", ""),
                    status,
                )
                return
            logger.warning(
                "LB %s reports pool %s as %s, should be %s",
                parsed.netloc,
                parsed.path.replace("/pools/", ""),
                status,
                desired_status,
            )
            # now wait before retrying
            time.sleep(self.wait)
        # We ran out of retries, raise an exception.
        if status is None:
            status = "Never successfully retrieved {}".format(url)
        raise PoolStatusError(str(status))


class PoolStatus:
    def __init__(self, enabled=True, pooled=True, up=True, weight=0):
        self.enabled = enabled
        self.pooled = pooled
        self.up = up
        self.weight = weight

    def has_state(self, want_pooled):
        # A server we want in the pool must be enabled/up/pooled
        # A server we don't want must be disabled/*/depooled
        return (
            self.enabled == want_pooled
            and self.pooled == want_pooled
            and not (want_pooled and not self.up)
        )

    def __str__(self):
        enabled = "enabled" if self.enabled else "disabled"
        up = "up" if self.up else "down"
        pooled = "pooled" if self.pooled else "not pooled"
        return "/".join([enabled, up, pooled])


class PoolStatusError(Exception):
    pass


def parse_args():
    parser = argparse.ArgumentParser(
        description="Safe script to restart services while depooled. "
        "Optionally, it can just depool/pool services."
    )
    parser.add_argument(
        "--config", help="Conftool config file", default="/etc/conftool/config.yaml"
    )
    parser.add_argument("--object-type", dest="object_type", default="node")
    parser.add_argument(
        "--debug", action="store_true", default=False, help="print debug info"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        default=False,
        help="Perform an unsafe restart (skips depool/repool)",
    )
    parser.add_argument(
        "--schema",
        default="/etc/conftool/schema.yaml",
        help="Schema file that defines additional object types",
    )
    parser.add_argument(
        "--retries",
        default=5,
        type=int,
        help="Number of times to retry verification on the LVS servers",
    )
    parser.add_argument(
        "--wait",
        default=3,
        type=int,
        help="How many seconds to wait before the next check upon an error",
    )
    parser.add_argument(
        "--timeout",
        default=5,
        type=int,
        help="Number of seconds to wait a response from the lbs",
    )
    parser.add_argument(
        "--grace-period",
        default=3,
        type=int,
        help="Number of seconds, if any, to wait after depooling a server before restarting it."
        " Defaults to 3 seconds",
    )
    parser.add_argument(
        "--catalog",
        dest="catalog",
        metavar="CATALOG",
        default="/etc/conftool/local_services.yaml",
        help="Location of the service catalog yaml",
    )
    parser.add_argument(
        "--pools",
        nargs="+",
        metavar="POOL",
        help="LVS services to depool",
    )
    if pc_support:
        parser.add_argument(
            "--max-concurrency",
            default=0,
            type=int,
            help="Limits the maximum number of restarts happening concurrently across the cluster.",
        )
        parser.add_argument(
            "--poolcounter-config",
            default="/etc/poolcounter-backends.yaml",
            help="Path to the poolcounter configuration yaml file. See python-poolcounter's docs.",
        )
    simple_actions = parser.add_mutually_exclusive_group(required=True)
    simple_actions.add_argument(
        "--services", nargs="+", metavar="SVC", help="Systemd service to restart"
    )
    simple_actions.add_argument(
        "--pool",
        action="store_true",
        default=False,
        help="Just repool (with verification) the indicated services",
    )
    simple_actions.add_argument(
        "--depool",
        action="store_true",
        default=False,
        help="Just depool (with verification) the indicated services",
    )
    return parser.parse_args()


def poolcounter_run(args, sr):
    try:
        key = sr.get_poolcounter_key()
    except ValueError as e:
        logger.error(e)
        return sr.DEFAULT_RC
    try:
        pc = poolcounter.from_yaml(args.poolcounter_config, "service_restarter")
    except Exception:
        logger.error(
            "Could not initialize poolcounter from file '%s'", args.poolcounter_config
        )
    # Run at most args.max_concurrency restarts at the same time across the cluster.
    # Only error out after 10 minutes.
    if pc.run(
        RequestType.LOCK_EXC,
        key,
        sr.run_and_raise,
        concurrency=args.max_concurrency,
        max_queue=10000,
        timeout=600,
    ):
        return 0
    else:
        return 2


def main():
    args = parse_args()
    log_format = "%(asctime)s [%(levelname)s] %(message)s"
    if args.debug:
        logging.basicConfig(level=logging.DEBUG, format=log_format)
    else:
        logging.basicConfig(level=logging.INFO, format=log_format)
        # We don't really want conftool/requests to pollute our output
        for lbl in ["conftool", "urllib3", "requests"]:
            logging.getLogger(lbl).setLevel(logging.WARNING)
    sr = ServiceRestarter(args)
    sr.setup()

    if args.depool:
        return sr.run_depool()
    if args.pool:
        return sr.run_pool()
    # If there is no poolcounter package installed,
    # we don't accept --max-concurrency as a cli argument
    # so guard the conditional with pc_support first.
    if pc_support and args.max_concurrency != 0:
        return poolcounter_run(args, sr)
    else:
        return sr.run()


if __name__ == "__main__":
    sys.exit(main())
