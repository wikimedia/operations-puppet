#!/usr/bin/python3
from distutils.version import StrictVersion
import argparse
import json
import logging

import redis
import requests
import yaml


LOG_FORMAT = "%(asctime)s %(message)s"
log = logging.getLogger()

services_registry = 'k8s_services'


class KubeAuth(requests.auth.AuthBase):
    """Add Authorization header to requests."""
    def __init__(self, token):
        self.token = token

    def __call__(self, r):
        r.headers['Authorization'] = 'Bearer {}'.format(self.token)
        return r


class KubeClient(object):

    def __init__(self, master, token, conn=redis.StrictRedis()):
        self.base_url = master
        self.session = requests.Session()
        self.session.auth = KubeAuth(token)
        self.conn = conn
        self.base_params = {
            'labelSelector': 'tools.wmflabs.org/webservice=true'
        }
        self.resourceVersion = 0

    def get_services(self):
        """Gets an initial list of all services"""
        log.debug('Searching for existing services')
        resp = self.session.get(self.url_for('/services'),
                                params=self.base_params)
        services = []
        try:
            servicelist = resp.json()
            self.resourceVersion = int(
                servicelist['metadata']['resourceVersion'])
            log.debug("global resourceVersion now at %s", self.resourceVersion)
            for servicedata in servicelist['items']:
                services.append(KubeClient._resp_to_service(servicedata))
            return services
        except:
            log.error("The services list was not correctly parsed.")
            raise

    def get_service(self, name, namespace):
        resp = self.session.get(
            self.url_for('/namespaces/{}/services/{}'.format(namespace, name)))
        if resp.status_code != '200':
            raise ValueError(
                "Found an unexpected response code %s when "
                "searching for service %s" % (resp.status_code, name))

    def sync_services(self):
        """Does a full sync of the services, returns a list
        of the active ones."""
        services = self.get_services()
        registered_services = set(
            [s.decode('utf-8') for s in self.conn.smembers(services_registry)])
        actual_services = set([str(s) for s in services])
        services_to_delete = registered_services - actual_services
        for service in services_to_delete:
            namespace, name, route = service.split('/')
            route = route.rstrip('.*')
            try:
                s = Service(name, namespace)
                s.route = route
                s.action = 'DELETED'
                services.append(s)
            except ValueError:
                log.warning("Could not find service %s, skipping", service)
                # TODO: remove it from the redis list anyways?

        return services

    @property
    def services(self):
        """yields any initial service and then any subsequent change"""
        # Custom-built badass event loop
        # Because python is webscale!!1!
        while True:
            # Note: if this fails we don't really want to recover
            for service in self.sync_services():
                yield service
            try:
                # this should watch forever
                resp = self.watch_services()
                for line in resp.iter_lines():
                    yield self._resp_to_service(
                        json.loads(line.decode('utf-8')))
            except Exception as e:
                # If watching fails, start from scratch
                log.error("An error occurred while watching for changes, "
                          "starting from scratch")
                log.exception("Exception was: %s", e, exc_info=True)
                pass

    def watch_services(self):
        """Request the watch url and return the response handle."""
        params = {'resourceVersion': self.resourceVersion, 'watch': True}
        params.update(self.base_params)
        return self.session.get(self.url_for('/watch/services'),
                                params=params, stream=True)

    def url_for(self, path):
        """Returns the full url for a specific path."""
        return "{}/api/v1{}".format(self.base_url, path)

    @staticmethod
    def _resp_to_service(data, action='ADDED'):
        """Transforms the response object into a Service object"""
        obj = data.get('object', data)
        action = data.get('type', action)
        metadata = obj.get('metadata')
        spec = obj.get('spec')
        name = metadata.get('name')
        namespace = metadata.get('namespace')
        ipaddr = spec.get('clusterIP')
        port = spec.get('ports').pop().get('port', "80")
        labels = metadata.get('labels', {})
        s = Service(name, namespace, ipaddr, port, labels)
        s.action = action
        return s


class Service(object):
    default_route = '.*'

    def __init__(self, name, namespace, ipaddr=None, port=None, labels=None):
        self.name = name
        self.namespace = namespace
        self.ipaddr = ipaddr
        self.labels = labels
        self.port = port
        self.action = 'ADDED'
        self._route = None

    @property
    def url(self):
        return "http://{}:{}".format(self.ipaddr, self.port)

    @property
    def route(self):
        if not self._route:
            route = self.labels.get('toollabs-proxy-path')
            if route:
                self._route = "/{}.*".format(route)
            else:
                self._route = self.default_route
        return self._route

    @route.setter
    def route(self, route):
        if not route or route == self.default_route:
            self._route = self.default_route
        else:
            self._route = "/{}.*".format(route)

    def write(self, conn):
        # TODO: for now it's ok to use the tool name as a
        # prefix; in the future we'll need to probably refine this a bit
        key = "prefix:%s" % self.name
        log.info("Service %s is %s", self, self.action)
        if self.action == 'ADDED':
            conn.hset(key, self.route, self.url)
            conn.sadd(services_registry, str(self))
        elif self.action == 'MODIFIED':
            oldroutes = conn.hgetall(key)
            conn.hset(key, self.route, self.url)
            conn.sadd(services_registry, str(self))
            for route, url in oldroutes.items():
                # a different url was pointing to our service
                if route != self.route and url == self.url:
                    log.info("Removing stale route %s for service %s/%s",
                             route, self.namespace, self.name)
                    conn.hdel(key, route)
                    setkey = str(self).replace(self.route, route)
                    conn.srem(setkey)
        elif self.action == 'DELETED':
            conn.hdel(key, self.route)
            conn.srem(services_registry, str(self))

    def __str__(self):
        r = self.route
        if r.startswith('/'):
            r = r[1:]
        return "{}/{}/{}".format(self.namespace, self.name, r)


def main():
    parser = argparse.ArgumentParser(
        description="Kubernetes to dynamicproxy syncronizer")
    parser.add_argument('--config',
                        help="Optional yaml config file")
    parser.add_argument('-d', '--debug', action='store_true')
    args = parser.parse_args()

    if args.debug:
        level = logging.DEBUG
    else:
        level = logging.INFO
    logging.basicConfig(format=LOG_FORMAT, level=level)

    # T213711: Verify that the version of requests we are seeing is new enough
    # to work for watching the Kubernetes API change stream.
    if StrictVersion(requests.__version__) < StrictVersion('2.7.0'):
        raise AssertionError(
            'kube2proxy needs requests>=2.7.0, found {}'.format(
                requests.__version__))

    with open(args.config, 'r') as fh:
        config = yaml.safe_load(fh)

    rhost, rport = config['redis'].split(':')
    conn = redis.Redis(host=rhost, port=rport)
    config['kubernetes']['conn'] = conn
    kubecl = KubeClient(**config['kubernetes'])
    for service in kubecl.services:
        service.write(conn)


if __name__ == '__main__':
    main()
