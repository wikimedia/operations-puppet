#!/usr/bin/python3

import argparse
import json
import os
import sys


def erase(host):
    """
    Does nothing as this credential helper does not store anything and so
    cannot erase anything.

    :param host: Host for which to erase stored credentials.
    """

    pass


def get(host):
    """
    Compares the given host to the set DOCKER_CREDENTIAL_HOST. If they match,
    returns the credentials stored in DOCKER_CREDENTIAL_USERNAME and
    DOCKER_CREDENTIAL_PASSWORD environment variables.

    :param host: Host for which the docker command requires authentiation.
                 Compared against the defined DOCKER_CREDENTIAL_HOST
                 environment variable.
    """

    if host == os.environ.get('DOCKER_CREDENTIAL_HOST'):
        return {'Username': os.environ.get('DOCKER_CREDENTIAL_USERNAME'),
                'Secret': os.environ.get('DOCKER_CREDENTIAL_PASSWORD')}
    return {}


def store(credsJSON):
    """
    Does nothing as this credential helper does not store anything.

    :param credsJSON: JSON payload containing host, username, password to
                      store.
    """

    pass


parser = argparse.ArgumentParser(description=(
    'Docker credential helper that returns credentials from environment '
    'variables DOCKER_CREDENTIAL_USERNAME and DOCKER_CREDENTIAL_PASSWORD. A '
    'DOCKER_CREDENTIAL_HOST variable must also be set to the registry '
    'hostname.'))

operations = {'erase': erase, 'get': get, 'store': store}
parser.add_argument('operation', type=str, choices=operations.keys())

args = parser.parse_args()

payload = sys.stdin.readline().strip()
result = operations[args.operation](payload)

if result is not None:
    print(json.dumps(result))
