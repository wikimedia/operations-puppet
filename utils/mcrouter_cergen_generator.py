#!/bin/env python3
#
# Generates the cergen yaml file for the mcrouter CA, then runs it
#
# Copyright 2018 - present Giuseppe Lavagetto
#

# We need a certificate for every server that has mediawiki installed

import argparse
import configparser
import os
import requests
import yaml

from cergen.certificate import Certificate
from cergen.main import certificates_status_string
from cergen.manifest import set_manifest_entry_defaults
from cergen.signer import SignerGraph

def hosts_from_puppetdb(configfile):
    c = configparser.Configparser()
    c.read(configfile)
    puppetdb_url = "{}/pdb/query/v4/resources".format(c['main']['server_urls'])
    r = requests.post(puppetdb_url, json={'query': ["and", ['=', 'type', 'Class'], ["=", "title", "Mediawiki"]] }, verify=True)
    if r.status_code != 200:
        raise ValueError("Got non-OK status code from puppetdb: %d", r.status_code)
    hosts = set([el['certname'] for el in r.json()])
    return list(hosts)

def cergen_manifests(hosts, ca_secret, base_path):
    data = {}
    data['mcrouter_ca'] = {
        'is_authority': True,
        'path_length': 1,
        'subject': {'country_name': 'US', 'state_or_province_name': 'CA'},
        'key': {'name': 'ca', 'key_size': 2048, 'algorithm': 'rsa', 'password': ca_secret}
    }

    def definition_for(host, ip):
        base = {
            'authority': 'mcrouter_ca',
            'subject': {
                'country_name': 'US',
                'state_or_province_name': 'CA',
                'organizational_unit_name': 'Wikimedia Foundation, Inc.'
            },
            'key': {'key_size': 2048, 'algorithm': 'rsa'},
            'alt_names': [ip],
            'key_usage': ['digital_signature', 'content_commitment', 'key_enchipherment']
        }
        return set_manifest_entry_defaults(base, host, base_path, base_path)

    for name, ip in hosts:
        data[name] = definition_for(name, ip)
    return data

def main():
    parser = argparse.ArgumentParser(description='generate the yaml files for cergen, then runs it')
    parser.add_argument('--puppetdb-config|-c', help='puppetdb config file',
                        default='/etc/puppet/puppetdb.conf', dest='puppetdb_config')
    parser.add_argument('--ca-secret|-C',
                        help='path of the file with the CA secret',
                        default='/srv/private/modules/secrets/secret/mcrouter/.ca_secret',
                        dest='ca_secret')
    parser.add_argument('--base-path|-b', help='base path for the generated certs',
                        default='/srv/private/modules/secrets/secret/mcrouter/certs',
                        dest='base_path')
    args = parser.parse_args()

    with open(args.ca_secret, 'rb') as fh:
        ca_secret = fh.read().decode('utf-8').strip()

    hosts = hosts_from_puppetdb(args.puppetdb_config)
    manifest = cergen_manifests(hosts, ca_secret, args.base_path)
    # Create a directed graph of Authorities and Certificates from the manifest.
    graph = SignerGraph(manifest)
    certificates = [c for c in graph.select() if isinstance(c, Certificate)]
    certificate_names = [c.name for c in certificates]
    print('Generating certificates')
    for certificate in certificates:
        certificate.generate(force=False)
    print("\nStatus of certificates {}".format(certificate_names))
    print(certificates_status_string(list(certificates)))
