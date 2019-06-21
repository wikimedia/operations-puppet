#!/usr/bin/python3
# TODO: add concurrency protection with poolcounter.
import argparse
import logging
import shlex
import socket
import subprocess
import re
import sys
import time

from urllib import parse

import requests

from conftool.cli.tool import ToolCliBase
from conftool.drivers import BackendError

logger = logging.getLogger('service_restarter')


class ServiceRestarter(ToolCliBase):

    # Default error return-code from the script itself
    DEFAULT_RC = 127

    def __init__(self, args):
        super().__init__(args)
        self.fqdn = socket.getfqdn()
        self.retries = args.retries
        self.wait = args.wait
        self.pools = args.pools
        self.lvs_uris = args.lvs_urls
        self.services = args.services
        self.timeout = args.timeout

    def announce(self):
        pass

    def _run_action(self):
        pass

    def run(self):
        """
        Finds if a service for a host is pooled or not.
        """
        pooled = self._get_objects()
        if not len(pooled):
            logger.info("The server is depooled from all services. Restarting the service directly")
            # Everything is depooled, we can just restart the services
            return self._restart_services()

        logger.info("Depooling currently pooled services")
        if not self.depool(pooled):
            return self.DEFAULT_RC
        logger.info("Restarting the service")
        rc = self._restart_services()
        # If the restart fails, we don't really want to repool.
        if rc != 0:
            logger.warn('Service restart failed. NOT repooling')
            return rc
        logger.info("Repooling previously pooled services")
        if not self.pool(pooled):
            return self.DEFAULT_RC
        return rc

    def _restart_services(self):
        for svc in self.services:
            cmd = ['systemctl', 'restart', svc + '.service']
            cmd_str = ' '.join(map(shlex.quote, cmd))
            try:
                subprocess.check_call(cmd)
                logger.debug('Execution of command %s successful', cmd_str)
                return 0
            except subprocess.CalledProcessError as e:
                logger.error('Executing command %s failed: %s', cmd_str, e)
                return e.returncode

    def _get_objects(self):
        """Gets the objects corresponding to the services we're operating on"""
        selector = {'service': re.compile('|'.join(self.pools)), 'name': re.compile(self.fqdn)}
        objects = list(self.entity.query(selector))
        pooled = [o for o in objects if o.pooled == 'yes']
        return pooled

    def depool(self, pooled):
        """Depool a list of services"""
        try:
            # First let's depool in etcd
            for obj in pooled:
                obj.update({'pooled': 'no'})
            # now let's wait for the services to be depooled in pybal
            self._verify_status(False)
            return True
        except (BackendError, PoolStatusError) as e:
            logger.error('Error depooling the servers: {}'.format(e))
            return False

    def pool(self, pooled):
        """Pool a list of services"""
        try:
            for obj in pooled:
                obj.update({'pooled': 'yes'})
            self._verify_status(True)
            return True
        except (BackendError, PoolStatusError) as e:
            logger.error('Error depooling the servers: {}'.format(e))
            return False

    def _verify_status(self, want_pooled):
        if want_pooled:
            desired_status = 'enabled/up/pooled'
        else:
            desired_status = 'disabled/*/not pooled'
        for baseurl in self.lvs_uris:
            parsed = parse.urlparse(baseurl)
            url = '{baseurl}/{fqdn}'.format(baseurl=baseurl, fqdn=self.fqdn)
            # This will raise a PoolStatusError
            logger.debug("Now verifying %s", url)
            self._fetch_retry(url, want_pooled, parsed, desired_status)

    def _fetch_retry(self, url, want_pooled, parsed, desired_status):
        headers = {
            'user-agent': 'service-restarter/0.0.1',
            'accept': 'application/json'
        }
        for _ in range(0, self.retries):
            try:
                logger.debug('Fetching url %s', url)
                r = requests.get(url, headers=headers, timeout=self.timeout)
                r.raise_for_status()
            except requests.exceptions.HTTPError:
                # If we don't get a valid response, we bail out of checking.
                # This will account for servers that are inactive (which will
                # return 404) and for backing off if pybal is unable to respond
                # (5xx errors)
                logger.debug('Invalid response (status code %s) for % - aborting',
                             r.status_code, url)
                return
            except requests.exceptions.Timeout:
                # In this case, we don't want to stampede pybal, we bail out
                logger.warning("Timed out checking %s", url)
                return
            except requests.exceptions.RequestException as e:
                logger.warning(
                    'Issues connecting to %s: %s',
                    parsed.netloc,
                    e
                )
                # For such errors, we just retry again
                continue

            # Now let's parse the response
            try:
                status = PoolStatus(**r.json())
            except Exception:
                # Malformed response. We bail out as well
                return

            if status.has_state(want_pooled):
                logger.debug(
                    'OK - LB %s reports pool %s as %s',
                    parsed.netloc,
                    parsed.path.replace('/pools/', ''),
                    status
                )
                return
            else:
                logger.warning(
                    'LB %s reports pool %s as %s, should be %s',
                    parsed.netloc,
                    parsed.path.replace('/pools/', ''),
                    status,
                    desired_status
                    )
                # now wait before retrying
                time.sleep(self.wait)
        # We ran out of retries, raise an exception.
        raise PoolStatusError(str(status))


class PoolStatus:
    def __init__(self, enabled=True, pooled=True, up=True):
        self.enabled = enabled
        self.pooled = pooled
        self.up = up

    def has_state(self, want_pooled):
        # A server we want in the pool must be enabled/up/pooled
        # A server we don't want must be disabled/*/depooled
        return (self.enabled == want_pooled
                and self.pooled == want_pooled
                and not (want_pooled and not self.up))

    def __str__(self):
        enabled = 'enabled' if self.enabled else 'disabled'
        up = 'up' if self.up else 'down'
        pooled = 'pooled' if self.pooled else 'not pooled'
        return '/'.join([enabled, up, pooled])


class PoolStatusError(Exception):
    pass


def parse_args():
    parser = argparse.ArgumentParser(
        description='Safe script to restart services while depooled'
    )
    parser.add_argument('--config', help='Conftool config file',
                        default='/etc/conftool/config.yaml')
    parser.add_argument('--object-type', dest='object_type', default='node')
    parser.add_argument('--debug', action='store_true',
                        default=False, help='print debug info')
    parser.add_argument(
        '--schema', default='/etc/conftool/schema.yaml',
        help='Schema file that defines additional object types'
    )
    parser.add_argument(
        '--retries',
        default=5,
        type=int,
        help='Number of times to retry verification on the LVS servers')
    parser.add_argument(
        '--wait',
        default=3,
        type=int,
        help='How many seconds to wait before the next check upon an error'
    )
    parser.add_argument(
        '--timeout',
        default=5,
        type=int,
        help='Number of seconds to wait a response from the lbs'
    )
    parser.add_argument(
        '--lvs-urls', dest='lvs_urls', nargs='+', metavar='URL',
        help='Full urls to check for results in pybal.'
    )
    parser.add_argument('--pools', nargs='+', metavar='POOL',
                        help='LVS services to depool')
    parser.add_argument('--services', nargs='+', metavar='SVC',
                        help='Systemd service to restart')
    return parser.parse_args()


def main():
    args = parse_args()
    log_format = '%(asctime)s [%(levelname)s] %(message)s'
    if args.debug:
        logging.basicConfig(level=logging.DEBUG, format=log_format)
    else:
        logging.basicConfig(level=logging.INFO, format=log_format)
        # We don't really want conftool/requests to pollute our output
        for lbl in ["conftool", "urllib3", "requests"]:
            logging.getLogger(lbl).setLevel(logging.WARNING)
    sr = ServiceRestarter(args)
    sr.setup()
    return sr.run()


if __name__ == '__main__':
    sys.exit(main())
