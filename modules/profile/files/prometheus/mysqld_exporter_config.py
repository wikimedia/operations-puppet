#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

"""
This script generates the prometheus-mysqld-exporter targets from the
zarcillo database so it doesn't have to be maintained
manually on different places
"""

import argparse
import logging
import os
import sys

import pymysql
import yaml

TLS_TRUSTED_CA = '/etc/ssl/certs/Puppet_Internal_CA.pem'
DB_CONFIG_FILE = '/etc/prometheus/zarcillo.cnf'
DATACENTERS = ['eqiad', 'codfw', 'esams', 'ulsfo', 'eqsin', 'drmrs']


def get_socket(instance):
    """
    Returns the prometheus listening socket address from the instance string.
    E.g. db1068 returns db1068:9104; db1098:3311 returns db1098:13311
    REMEMBER to change role::prometheus::mysqld_exporter,
    profile::mariadb::*multiinstance if you change this.
    """
    if ':' not in instance:
        return f'{instance}:9104'
    host, port = instance.rsplit(':', 1)
    return f'{host}:{int(port) + 10000}'


def get_options():
    """
    Return an object with the datacenter to be monitored and the path of the prometheus job
    configuration as read from the command line arguments
    """
    parser = argparse.ArgumentParser(description='Generate mysql prometheus exporter targets.')
    parser.add_argument('dc', choices=DATACENTERS,
                        help='Datacenter to generate files for.')
    parser.add_argument('config_path',
                        help='Absolute path of the location of prometheus job configuration.')
    options = parser.parse_args()
    return options


def get_db_config():
    """
    Read from a local file and return the database configuration parameters
    """
    logger = logging.getLogger('prometheus')
    try:
        config = yaml.safe_load(open(DB_CONFIG_FILE))
    except yaml.YAMLError:
        logger.exception('Error opening or parsing the YAML config file')
        sys.exit(1)
    except FileNotFoundError:
        logger.exception('Config file not found')
        sys.exit(2)
    if not isinstance(config, dict) or 'host' not in config:
        logger.error('Error reading host from config file')
        sys.exit(3)

    return (config.get('host'), config.get('port'), config.get('database'), config.get('user'),
            config.get('password'))


def get_data(host, port, database, user, password, dc):
    """
    Connect to the database, query all needed data, do basic checks (e.g. no empty results)
    and return it as is.
    """
    logger = logging.getLogger('prometheus')
    try:
        db = pymysql.connect(host=host, port=port, database=database,
                             user=user, password=password,
                             ssl={'ca': TLS_TRUSTED_CA}, connect_timeout=10)
    except pymysql.err.OperationalError:
        logger.exception('We could not connect to %s to store the stats', host)
        sys.exit(4)

    # query instances and its sections, groups and if they are masters or not
    query = """SELECT instances.name AS name, instances.group AS `group`, sections.name AS section,
               IF(sections.standalone, 'standalone',
               IF (isnull(masters.instance), 'slave', 'master')) AS role
               FROM section_instances
               LEFT JOIN sections ON sections.name=section_instances.section
               JOIN instances ON section_instances.instance = instances.name
               LEFT JOIN masters ON section_instances.instance = masters.instance
               WHERE instances.server like %s
               ORDER BY name, section, role"""

    # expected results: name | group | section | role
    #                   db1  | core  | s1      | slave
    #                   db2  | misc  | s3      | master
    #                   db3  | labs  | m4      | standalone
    with db.cursor(pymysql.cursors.DictCursor) as cursor:
        try:
            cursor.execute(query, ('%.' + dc + '.wmnet',))
        except (pymysql.err.ProgrammingError, pymysql.err.InternalError):
            logger.exception('A MySQL error occurred while quering the instances')
            sys.exit(5)
        data = cursor.fetchall()
        # Check we have a number of reasonable results depending on the dc
        if (((len(data) < 10 or len(data) > 1000) and dc in ['eqiad', 'codfw'])
                or (len(data) > 0 and dc not in ['eqiad', 'codfw'])):
            logger.error('The number of obtained results is different than expected')
            sys.exit(6)
    db.close()
    return data


def transform_data_to_prometheus(data):
    """
    Transforms the data as received in the database format to the one
    expected by the prometheus job configuration
    """
    # convert database format to dictionary. Eg.:
    # core:                <-- group
    #   s1:                <-- section (shard)
    #     master:          <-- role
    #       - db1163:9104  <-- list of sockets
    #     slave:
    #       - db1169:11311
    #       - db1134:9104
    logger = logging.getLogger('prometheus')
    instances = dict()
    for instance in data:
        name = get_socket(instance['name'])
        group = instance['group']
        section = instance['section']
        role = instance['role']
        if role not in ['master', 'slave', 'standalone']:  # Some es* hosts are special ones
            logger.error('A role other than master, replica or standalone was found')
            sys.exit(7)
        if group not in instances:
            instances[group] = dict()
        if section not in instances[group]:
            instances[group][section] = dict()
        if role not in instances[group][section]:
            instances[group][section][role] = list()
        instances[group][section][role].append(name)

    # transform to prometheus weird format. E.g.:
    # core:
    # - labels:
    #     shard: s1
    #     role: master
    #   targets:
    #     - db1163:9104
    # - labels:
    #     shard: s1
    #     role: slave
    #   targets:
    #     - db1169:11311
    #     - db1134:9104
    prometheus = dict()
    for group, sections in sorted(instances.items()):
        prometheus[group] = list()
        try:
            for section, roles in sorted(sections.items()):
                for role, targets in sorted(roles.items()):
                    labels = dict()
                    labels['shard'] = section
                    labels['role'] = role
                    item = dict()
                    item['labels'] = labels
                    item['targets'] = targets
                    prometheus[group].append(item)
        except TypeError:
            logger.error('The query returned instances with NULL sections, aborting.')
            logger.error('Check the instances, section_instances or sections tables.')
            sys.exit(8)
    return prometheus


def check_and_write_to_disk(prometheus, dc, config_path):
    """
    Compares existing and new content about to be written, and if it is different, it
    overwrites it
    """
    logger = logging.getLogger('prometheus')
    for group, sections in sorted(prometheus.items()):
        filename = f'mysql-{group}_{dc}.yaml'
        path = os.path.join(config_path, filename)
        try:
            previous_config = open(path, 'r').read()
        except FileNotFoundError:
            logger.debug('Prometheus file not found')
            previous_config = None
        except IOError:
            logger.exception('Error while reading original file')
            sys.exit(8)
        new_config = yaml.dump(sections, default_flow_style=False)
        if previous_config == new_config:
            logger.debug('%s is identical to the new one queries, '
                         'skiping overwrite', filename)
        else:
            try:
                with open(path, 'w') as outfile:
                    yaml.dump(sections, outfile, default_flow_style=False)
            except IOError:
                logger.exception('Error updating file %s', filename)
                sys.exit(9)
            logger.info('%s was modified', filename)


def main():
    """
    Reads the instance configuration from the database and, if it changed,
    overwrite the prometheus mysqld exporter job scheduling config.
    """
    # get datacenter and prometheus config path from command line
    options = get_options()
    dc = options.dc
    config_path = options.config_path

    # Read database connection configuration from file
    host, port, database, user, password = get_db_config()

    # Connect to the database and gather data
    data = get_data(host, port, database, user, password, dc)

    # transform data to the prometheus format
    prometheus = transform_data_to_prometheus(data)

    # write yaml to disk
    check_and_write_to_disk(prometheus, dc, config_path)


if __name__ == "__main__":
    main()
