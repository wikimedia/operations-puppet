#!/usr/bin/env python3
"""Query the JumpCloud api to produce a list of managed email accounts"""
import logging

from argparse import ArgumentParser
from configparser import ConfigParser
from json.decoder import JSONDecodeError
from os import path
from typing import Set

from requests import get, HTTPError


def get_args():
    """Parse arguments"""
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-c', '--config-file', default='/etc/jumpcloud.ini')
    parser.add_argument('-v', '--verbose', action='count')
    return parser.parse_args()


def get_log_level(args_level):
    """Configure logging"""
    return {
        None: logging.ERROR,
        1: logging.WARN,
        2: logging.INFO,
        3: logging.DEBUG}.get(args_level, logging.DEBUG)


def get_aliases(domain: str, api_uri: str, api_key: str) -> Set:
    """query jumpcloud and return a set of aliases for a given domain

    :Parameters:
        domain (str): The domain to filter on
        api_uri (str): The uri for the jumpcloud api and point
        api_key (str): The API key for the jumpcloud api and point

    Returns:
        Set: a set of aliases in the given domain
    """
    headers = {'x-api-key': api_key}
    uri = '{}/{}'.format(api_uri, 'systemusers')
    response = get(uri, headers=headers, json={'fields': 'email'})
    response.raise_for_status()

    try:
        response = response.json()
    except JSONDecodeError as error:
        logging.error('Enable to parse response: %s', response.text)
        raise error

    return set(data['email'].split('@')[0] for data in response['results']
               if data['email'].split('@')[1] == domain)


def main():
    """main entry point"""
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    config = ConfigParser()
    config.read(args.config_file)
    for key, value in config['DEFAULT'].items():
        logging.debug('loaded %s: %s', key, value)
    try:
        aliases = get_aliases(
            config.get('DEFAULT', 'managed_domain'),
            config.get('DEFAULT', 'api_uri'),
            config.get('DEFAULT', 'api_key'))
    except HTTPError as error:
        logging.error('Unable to fetch users: %s', error)
        return 1
    except JSONDecodeError:
        return 1
    logging.debug('received the following aliases: %s', ','.join(aliases))
    aliases_file = path.join(
        config.get('DEFAULT', 'aliases_directory'),
        config.get('DEFAULT', 'managed_domain'))
    with open(aliases_file, 'w') as out_file:
        out_file.write('\n'.join(aliases))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
