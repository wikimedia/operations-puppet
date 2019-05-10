#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
# python 3 compatibility
try:
    import ConfigParser as configparser
except ImportError:
    import configparser
import logging
import sys
import time

from logging.handlers import SysLogHandler

import jinja2
import requests
import sqlalchemy

# Taken from https://www.icinga.com/docs/icinga1/latest/en/objectdefinitions.html
VALID_HOST_PARAMS = [
    'host_name',
    'alias',
    'display_name',
    'address',
    'address6',
    'parents',
    'hostgroups',
    'check_command',
    'initial_state',
    'max_check_attempts',
    'check_interval',
    'retry_interval',
    'active_checks_enabled',
    'passive_checks_enabled',
    'check_period',
    'obsess_over_host',
    'check_freshness',
    'freshness_threshold',
    'event_handler',
    'event_handler_enabled',
    'low_flap_threshold',
    'high_flap_threshold',
    'flap_detection_enabled',
    'flap_detection_options',
    'failure_prediction_enabled',
    'process_perf_data',
    'retain_status_information',
    'retain_nonstatus_information',
    'contacts',
    'contact_groups',
    'notification_interval',
    'first_notification_delay',
    'notification_period',
    'notification_options',
    'notifications_enabled',
    'stalking_options',
    'notes',
    'notes_url',
    'action_url',
    'icon_image',
    'icon_image_alt',
    'statusmap_image',
    '2d_coords'
]
VALID_SERVICE_PARAMS = [
    'host_name',
    'hostgroup_name',
    'service_description',
    'display_name',
    'servicegroups',
    'is_volatile',
    'check_command',
    'initial_state',
    'max_check_attempts',
    'check_interval',
    'retry_interval',
    'active_checks_enabled',
    'passive_checks_enabled',
    'check_period',
    'obsess_over_service',
    'check_freshness',
    'freshness_threshold',
    'event_handler',
    'event_handler_enabled',
    'low_flap_threshold',
    'high_flap_threshold',
    'flap_detection_enabled',
    'flap_detection_options',
    'failure_prediction_enabled',
    'process_perf_data',
    'retain_status_information',
    'retain_nonstatus_information',
    'notification_interval',
    'first_notification_delay',
    'notification_period',
    'notification_options',
    'notifications_enabled',
    'contacts',
    'contact_groups',
    'stalking_options',
    'notes',
    'notes_url',
    'action_url',
    'icon_image',
    'icon_image_alt'
]


class NagiosGeneratorBase(object):
    restype = {
        'services': 'Nagios_service',
        'hosts': 'Nagios_host',
    }

    restpl = {
        'services': """define service {
# --PUPPET_NAME-- {{ name }}
{% for line in data -%}
{%- if line[1] is not none and line[1] != '' -%}
{{ "\t%-30s %s" % line }}
{%- endif %}
{% endfor %}
}
""",
        'hosts': """define host {
{% for line in data -%}
{{ "\t%-30s %s" % line }}
{% endfor %}
}
"""
    }

    def load_config(self, configfile):
        self.config = configparser.SafeConfigParser()
        self.config.read(configfile)

    def __init__(self, configfile, debug):
        self.log = logging.getLogger('naggen2')
        self.log.debug('Loading configfile %s', configfile)
        self.load_config(configfile)
        self.env = jinja2.Environment(
            loader=jinja2.DictLoader(self.restpl)
        )

    def render(self, what):
        if what not in self.restype:
            self.log.error('Exiting  - unsupported resource type %s', what)
            sys.exit(1)
        try:
            data = {}
            entities = set()
            tpl = self.env.get_template(what)
            for entity in self._query(what):
                self.log.debug('Working on resource %s', entity['title'])
                name, content = self._filter_entity(entity, what)
                data[name] = content
                if name in entities:
                    self.log.warn('Duplicate definition for %s', name)
                    continue
                entities.add(name)
            for name in sorted(entities):
                yield tpl.render(name=name, data=data[name])
        except Exception:
            self.log.exception(
                'Could not generate output for resource %s', what)
            sys.exit(30)

    def _query(self, what):
        raise NotImplementedError("Not implemented in the base class")


class NagiosGeneratorMysql(NagiosGeneratorBase):
    base_query = """
SELECT resources.title as title,
  GROUP_CONCAT(CONCAT(param_names.name, "\t", param_values.value)
    ORDER BY param_names.name ASC SEPARATOR "\n") AS service_content
FROM param_values
  JOIN param_names ON param_names.id = param_values.param_name_id
  JOIN resources ON param_values.resource_id = resources.id
WHERE param_names.name NOT IN ('ensure', 'target') AND resource_id IN
  (SELECT resource_id FROM param_values
    JOIN resources ON resource_id = resources.id
    JOIN param_names ON param_names.id = param_name_id
    WHERE restype = '%s' AND exported = true AND param_names.name = 'ensure' AND value = 'present')
GROUP BY resources.id ORDER BY resources.title ASC"""

    def load_config(self, configfile):
        super(NagiosGeneratorMysql, self).load_config(configfile)
        self.dsn = "{}://{}:{}@{}:3306/puppet".format(
            self.config.get('master', 'dbadapter'),
            self.config.get('master', 'dbuser'),
            self.config.get('master', 'dbpassword'),
            self.config.get('master', 'dbserver')
        )

    def __init__(self, configfile, debug):
        super(NagiosGeneratorMysql, self).__init__(configfile, debug)
        self.db_engine = sqlalchemy.create_engine(
            self.dsn,
            echo=debug
        )

    def _query(self, what):
        connection = self.db_engine.connect()
        connection.execute('set group_concat_max_len = @@max_allowed_packet')
        res = connection.execute(self.base_query % self.restype[what])
        connection.close()
        return res

    def _filter_entity(self, entity, what):
        return (entity['title'], [
            tuple(i.split("\t"))
            for i in entity['service_content'].split("\n")
            if i])


class NagiosGeneratorPuppetDB(NagiosGeneratorBase):

    def load_config(self, configfile):
        super(NagiosGeneratorPuppetDB, self).load_config(configfile)

    def _query(self, what):
        try:
            # puppetdb terminus supports listing multiple puppetdb servers
            # we will use the first server listed
            server_urls = self.config.get('main', 'server_urls')
            server_url = server_urls.split(',')[0]
            url = "%s/pdb/query/v4/resources/%s" % (
                server_url,
                self.restype[what]
            )
        except configparser.NoOptionError:
            self.log.debug(
                    'PuppetDB version 4 setting "server_urls" not found in configfile. ',
                    'Trying PuppetDB version 2 settings "server" "port" and PuppetDB API v3.')
            url = "https://%s:%s/v3/resources/%s" % (
                self.config.get('main', 'server'),
                self.config.get('main', 'port'),
                self.restype[what]
            )
        else:
            self.log.debug('Found PuppetDB version 4 setting "server_urls" in configfile. ',
                           'Using PuppetDB API v4.')

        resources_raw = requests.get(url, params={
            'query': '["and", \
                        ["=", ["parameter", "ensure"], "present"], \
                        ["=", "exported", true] \
                    ]',
        })
        return resources_raw.json()

    def _filter_entity(self, entity, what):
        name = entity['title']
        # PuppetDB 2.3 does not collect the host_name parameter, apparently
        if what in ['hosts']:
            if 'host_name' not in entity['parameters']:
                entity['parameters']['host_name'] = entity['title']
        if what == 'hosts':
            valid_params = VALID_HOST_PARAMS
        elif what == 'services':
            valid_params = VALID_SERVICE_PARAMS
        param_keys = sorted([key for key in entity['parameters'].keys() if key in valid_params])
        params = [(p, entity['parameters'][p]) for p in param_keys]
        return (name, params)


def main():
    parser = argparse.ArgumentParser(
        description=(
            'Nagios config file generator -- Outputs a Nagios service or host config from a ',
            'PuppetDB or MySQL(deprecated) backend.'),
        epilog=(
            'Note: Environment variable REQUESTS_CA_BUNDLE may be used to specify the CA ',
            'certificate bundle location (file or directory) used when establishing HTTPS ',
            'connection to PuppetDB.'))
    parser.add_argument('--type', '-t', dest='type', help="type of file to generate",
                        choices=['services', 'hosts'])
    parser.add_argument('--configfile', '-c', dest='configfile', default='/etc/puppet/puppet.conf')
    parser.add_argument('--debug', action='store_true', default=False)
    parser.add_argument('--puppetdb', action='store_true', default=False)
    parser.add_argument('--activerecord', action='store_false', dest='puppetdb')
    args = parser.parse_args()

    log_format = '%(name)s: %(levelname)s - %(message)s'
    log = logging.getLogger('naggen2')

    if not args.debug:
        # if normal mode, log to syslog
        log.setLevel(logging.INFO)
        log.propagate = False
        handler = SysLogHandler(
            address='/dev/log',
            facility=SysLogHandler.LOG_LOCAL3)
        formatter = logging.Formatter(fmt=log_format)
        handler.setFormatter(formatter)
        log.addHandler(handler)
    else:
        # if debug mode, print to stderr
        logging.basicConfig(level=logging.DEBUG, format=log_format)

    # Redirect warnings to logging, instead of stderr
    logging.captureWarnings(True)

    log.info('Generating output for resource %s', args.type)
    tstart = time.time()
    if args.puppetdb:
        if args.configfile == '/etc/puppet/puppet.conf':
            configfile = '/etc/puppet/puppetdb.conf'
        else:
            configfile = args.configfile
        log.debug("Querying puppetdb for resources")
        n = NagiosGeneratorPuppetDB(configfile, args.debug)
    else:
        n = NagiosGeneratorMysql(args.configfile, args.debug)
    for entity in n.render(args.type):
        print(entity)
    log.info('Run completed in %.2f seconds', (time.time() - tstart))


if __name__ == '__main__':
    main()
