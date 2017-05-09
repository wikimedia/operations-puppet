#!/usr/bin/python3

import argparse
import logging
import shlex
import subprocess
import sys

QCONF_COMMANDS = {
    'global': '-sconf',
    'queues': '-sq',
    'quotas': '-srqs',
    'checkpoints': '-sckpt',
    'scheduler': '-ssconf'
}

GRID_RESOURCES = {
    'queues': ['task', 'webgrid-generic', 'webgrid-lighttpd',
               'continuous', 'mailq', 'giftbot'],
    'quotas': ['user_slots'],
    'checkpoints': ['continuous']
}


def parse_grid_config(resource_type, resource_name=''):
    """
    Read current resource config from an gridengine admin node using qconf,
    parse into python dict.
    :param resource_type: str
    :param resource_name: str
    :returns: dict
    """
    if resource_type not in QCONF_COMMANDS:
        logging.error('Invalid resource type {}, cannot parse gridengine config'
                      .format(resource_type))
    qconf_cmd = 'qconf {}{}'.format(QCONF_COMMANDS[resource_type],
                                    ' ' + resource_name)
    try:
        qconf_result_raw = subprocess.check_output(shlex.split(qconf_cmd))\
            .decode('utf-8')
        qconf_result_list = [line.split(maxsplit=1)
                             for line in qconf_result_raw.split('\n')]
        qconf_result_parsed = {}
        skip_next = False
        for i, result in enumerate(qconf_result_list):
            if skip_next:
                skip_next = False
                continue
            if result and len(result) == 2:
                # Handle multiline config values
                if result[1].endswith('\\'):
                    result[1] = result[1][:-1] + " ".join(qconf_result_list[i+1])
                    skip_next = True
                qconf_result_parsed[result[0]] = result[1]
        return qconf_result_parsed
    except subprocess.CalledProcessError as e:
        logging.error(e)
        return False


def parse_config_file(file_path):
    """
    Parse config file for a gridengine resource into python dict
    :param file_path: str
    :returns: dict
    """
    with open(file_path, 'r') as config_file:
        config_raw = [line.strip('\n').split(maxsplit=1)
                      for line in config_file.readlines()
                      if not line.startswith('#')]
        config_parsed = {}
        skip_next = False
        for i, c in enumerate(config_raw):
            if skip_next:
                skip_next = False
                continue
            if c and len(c) == 2:
                # Handle multiline config values
                if c[1].endswith('\\'):
                    c[1] = c[1][:-1] + " ".join(config_parsed[i+1])
                    skip_next = True
                config_parsed[c[0]] = c[1]
        return config_parsed


def config_match(grid_config, file_config):
    """
    Compare the current grid config and the expected config defined in the file
    for a gridengine resource and return boolean match
    :param grid_config: dict
    :param file_config: dict
    :returns: bool
    """
    return grid_config == file_config


def diff_config(grid_config, file_config, resource, resource_name=None):
    """
    Log differences between grid config (currently found) and file config
    (expected config)
    :param grid_config: dict
    :param file_config: dict
    :param resource: string
    :param resource_name: string
    """
    all_keys = set(grid_config.keys()) | set(file_config.keys())
    differences = []
    for key in list(all_keys):
        if file_config.get(key) != grid_config.get(key):
            differences.append("{}: Expected '{}' but found '{}'".format(
                key, file_config.get(key), grid_config.get(key)))
    if differences:
        logging.error("Config mismatch for resource {}:{}"
                      .format(resource, resource_name))
        logging.error('\n'.join(differences))


def main():

    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        '-config_path',
        default='/var/lib/gridengine/etc',
        help='Path on disk under which to setup the share tree',
    )

    argparser.add_argument(
        '-debug',
        help='Turn on debug logging',
        action='store_true'
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug else logging.INFO)

    resources = QCONF_COMMANDS.keys()
    mismatched = False
    for resource in resources:
        if GRID_RESOURCES.get(resource):
            for resource_name in GRID_RESOURCES[resource]:
                grid_config = parse_grid_config(resource, resource_name)
                file_config = parse_config_file("{}/{}/{}".format(
                    args.config_path,
                    resource,
                    resource_name))
                if not config_match(grid_config, file_config):
                    mismatched = True
                    diff_config(grid_config, file_config, resource, resource_name)

        else:
            grid_config = parse_grid_config(resource)
            file_config = parse_config_file("{}/{}/{}".format(
                args.config_path,
                'config',
                resource))
            if not config_match(grid_config, file_config):
                mismatched = True
                diff_config(grid_config, file_config, resource)

    if mismatched:
        sys.exit(1)


if __name__ == '__main__':
    main()
