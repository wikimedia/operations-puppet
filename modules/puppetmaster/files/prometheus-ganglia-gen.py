#!/usr/bin/env python
# Generate prometheus targets to be polled, based on puppet's exported
# resource Ganglia::Cluster.


import argparse
import collections
import logging
import re
import sys
import yaml
import ConfigParser as configparser

from logging.handlers import SysLogHandler

import sqlalchemy


Host = collections.namedtuple('Host', 'fqdn name cluster site')


class PrometheusClusterGen(object):
    query = """
        SELECT resources.title as title,
            GROUP_CONCAT(CONCAT(param_names.name, "\t", param_values.value)
            SEPARATOR "\n") AS service_content
        FROM param_values
            JOIN param_names ON param_names.id = param_values.param_name_id
            JOIN resources ON param_values.resource_id = resources.id
        WHERE restype = 'Ganglia::Cluster'
        GROUP BY resources.id ORDER BY resources.title ASC
        """

    def load_config(self, configfile):
        self.config = configparser.SafeConfigParser()
        self.config.read(configfile)
        self.dsn = "{}://{}:{}@{}:3306/puppet".format(
            self.config.get('master', 'dbadapter'),
            self.config.get('master', 'dbuser'),
            self.config.get('master', 'dbpassword'),
            self.config.get('master', 'dbserver')
        )

    def __init__(self, configfile, debug):
        self.log = logging.getLogger('prometheus-ganglia-gen')
        self.log.debug('Loading configfile %s', configfile)
        self.load_config(configfile)
        self.db_engine = sqlalchemy.create_engine(
            self.dsn,
            echo=debug
        )

    def _query(self):
        connection = self.db_engine.connect()
        connection.execute('set group_concat_max_len = @@max_allowed_packet')
        res = connection.execute(self.query)
        connection.close()
        return res

    def _hosts(self):
        try:
            for entity in self._query():
                attrs = collections.defaultdict(list)
                for restuple in entity['service_content'].split("\n"):
                    (k, v) = restuple.split("\t")
                    attrs[k].append(v)

                h = Host(
                        fqdn=entity['title'],
                        name=entity['title'].split('.')[0],
                        cluster=attrs['cluster'][0],
                        site=attrs['site'][0])
                yield h
        except Exception:
            self.log.exception(
                    'Could not generate output for resource Ganglia::Cluster')
            sys.exit(30)

    def site_targets(self, sites, filter_hostnames=None, target_suffix=':9100'):
        if filter_hostnames is None:
            filter_hostnames = []

        all_clusters = collections.defaultdict(list)
        for host in self._hosts():
            if sites and host.site not in sites:
                continue
            if filter_hostnames:
                if not any([re.match(x, host.name) for x in filter_hostnames]):
                    continue
            cluster_id = (host.cluster, host.site)
            all_clusters[cluster_id].append(host)

        targets = []
        for cluster_id, hosts in all_clusters.iteritems():
            target = {}
            cluster_name, cluster_site = cluster_id
            target['labels'] = {'cluster': cluster_name}
            if not sites:
                target['labels'].update({'site': cluster_site})
            target['targets'] = ["".join((x.name, target_suffix)) for x in hosts]
            targets.append(target)

        return targets


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--configfile', '-c', dest='configfile',
                        default='/etc/puppet/puppet.conf')
    parser.add_argument('--site', dest='sites', metavar='SITE', nargs='+')
    parser.add_argument('--filter-hostname', dest='filter_hostnames',
                        metavar='REGEXP', nargs='+')
    parser.add_argument('--debug', action='store_true', default=False)
    args = parser.parse_args()

    log_format = '%(name)s: %(levelname)s - %(message)s'
    log = logging.getLogger('prometheus-ganglia-gen')

    logging.basicConfig(level=logging.DEBUG, format=log_format, stream=sys.stderr)

    if not args.debug:
        log.setLevel(logging.INFO)
        log.propagate = False
        handler = SysLogHandler(
                address='/dev/log',
                facility=SysLogHandler.LOG_LOCAL3)
        formatter = logging.Formatter(fmt=log_format)
        handler.setFormatter(formatter)
        log.addHandler(handler)

    log.info('Generating prometheus cluster targets for sites %r' % args.sites)
    clustergen = PrometheusClusterGen(args.configfile, args.debug)
    print yaml.dump(clustergen.site_targets(args.sites, args.filter_hostnames),
                    default_flow_style=False)
    log.info('Run completed')


if __name__ == '__main__':
    main()
