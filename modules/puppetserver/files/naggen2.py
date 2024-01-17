#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import configparser
import logging
import sys
import time

from logging.handlers import SysLogHandler
from string import Template

import requests

STATIC_CONFIG = {
    'hosts': {
        'puppet_resource_type': 'Nagios_host',
        'template': Template('define host {\n$content\n\n}'),
        # https://www.icinga.com/docs/icinga1/latest/en/objectdefinitions.html#host
        'valid_params': [
            'host_name',
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
            '2d_coords',
        ]
    },
    'services': {
        'puppet_resource_type': 'Nagios_service',
        'template': Template(
            'define service {\n# --PUPPET_NAME-- $name\n$content\n\n}'
        ),
        # https://www.icinga.com/docs/icinga1/latest/en/objectdefinitions.html#service
        'valid_params': [
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
            'icon_image_alt',
        ]
    }
}
ICINGA_LINE_LENGTH = 32


class NagiosGeneratorPuppetDB:

    def __init__(self, configfile):
        self.log = logging.getLogger('naggen2')
        self.log.debug('Loading configfile %s', configfile)
        self.config = configparser.ConfigParser()
        self.config.read(configfile)

    @staticmethod
    def _format_content(params):
        """
        take a dict of params and return an icinga config formatted string

        :param params: dict
        :return: str
        """
        output = []
        for key, value in sorted(params.items()):
            line = '\t{}'.format(key).ljust(ICINGA_LINE_LENGTH, ' ')
            line += str(value).replace('\n', '')  # remove all new line chars from value
            output.append(line)
        return '\n'.join(output)

    def render(self, what):
        """
        generator that yields each rendered icinga configuration object

        :param what: str the STATIC_CONFIG key to use
        """
        definition = STATIC_CONFIG.get(what)
        if not definition:
            self.log.error("Exiting  - unsupported resource type %s", what)
            sys.exit(1)
        data = {}
        try:
            for entity in self._query(definition['puppet_resource_type']):
                self.log.debug('Working on resource %s', entity['title'])
                name, params = self._filter_entity(
                    entity, definition['valid_params'], what)
                if name in data.keys():
                    self.log.warning('Duplicate definition for %s', name)
                    continue
                data[name] = self._format_content(params)
            for name, content in sorted(data.items()):
                yield definition['template'].substitute(
                    name=name, content=content)
        except Exception:
            self.log.exception(
                'Could not generate output for resource %s', what)
            sys.exit(30)

    def _query(self, resource_type):
        """
        query puppetdb API v4 for resources of specified type

        :param resource_type: Puppet resource type to query for
        :return: dict raw response from puppetdb
        """
        # puppetdb terminus supports listing multiple puppetdb servers
        # we will use the first server listed
        server_urls = self.config.get('main', 'server_urls')
        server_url = server_urls.split(',')[0]
        url = "{0}/pdb/query/v4/resources/{1}".format(
            server_url,
            resource_type
        )
        resources_raw = requests.get(url, params={
            'query': '["and", \
                        ["=", ["parameter", "ensure"], "present"], \
                        ["=", "exported", true] \
                    ]',
        })
        return resources_raw.json()

    @staticmethod
    def _filter_entity(entity, valid_params, what):
        """
        ensure host_name is in parameters and filter out invalid parameters

        :param entity: the raw entity response from puppetdb
        :param valid_params: list of parameters that are valid for this entity
        :param what: str the STATIC_CONFIG key to use
        :return: tuple str name, dict params
        """
        clean_paramaters = {
            key: value for key, value in entity['parameters'].items() if key in valid_params
        }
        # inject host_name parameter for host objects from title
        if 'host_name' not in clean_paramaters:
            clean_paramaters['host_name'] = entity['title']
        # inject alias if we should be paging
        if what == 'hosts' and 'sms' in entity['parameters']['contact_groups'].split(','):
            clean_paramaters['alias'] = f"{clean_paramaters['host_name']} #page"
        return entity['title'], clean_paramaters


def main():
    parser = argparse.ArgumentParser(
        description=('Nagios config file generator -- Outputs a Nagios service'
                     ' or host config from PuppetDB resources'),
        epilog=('Note: Environment variable REQUESTS_CA_BUNDLE may be used to'
                ' specify the CA certificate bundle location (file or'
                ' directory) used when establishing HTTPS connection to'
                ' PuppetDB.')
    )
    parser.add_argument('--type', '-t', dest='type',
                        help="type of file to generate",
                        choices=['services', 'hosts'])
    parser.add_argument('--configfile', '-c', dest='configfile',
                        default='/etc/puppet/puppetdb.conf')
    parser.add_argument('--debug', action='store_true', default=False)
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
    n = NagiosGeneratorPuppetDB(args.configfile)
    for entity in n.render(args.type):
        print(entity)
    log.info('Run completed in %.2f seconds', (time.time() - tstart))


if __name__ == '__main__':
    main()
