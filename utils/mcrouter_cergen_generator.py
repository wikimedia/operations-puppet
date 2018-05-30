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

from cergen.main import main as cergen_main


def hosts_from_puppetdb(configfile):
    c = configparser.Configparser()
    c.read(configfile)
    puppetdb_url = "{}/pdb/query/v4/resources".format(c['main']['server_urls'])
    r = requests.post(puppetdb_url,
                      json={'query': ["and", ['=', 'type', 'Class'], ["=", "title", "Mediawiki"]]},
                      verify=True)
    if r.status_code != 200:
        raise ValueError("Got non-OK status code from puppetdb: %d", r.status_code)
    hosts = set([el['certname'] for el in r.json()])
    return list(hosts)


def cergen_manifests(hosts):

    def definition_for(ip):
        return {
            'authority': 'mcrouter_ca',
            'subject': {
                'country_name': 'US',
                'state_or_province_name': 'CA',
                'organizational_unit_name': 'Wikimedia Foundation, Inc.'
            },
            #  mcrouter seems not to work with ecdsa certs
            'key': {'key_size': 2048, 'algorithm': 'rsa'},
            'alt_names': [ip],
            'key_usage': ['digital_signature', 'content_commitment', 'key_enchipherment']
        }

    return {name: definition_for(ip) for name, ip in hosts}


def main():
    parser = argparse.ArgumentParser(description='generate the yaml files for cergen, then runs it')
    parser.add_argument('--puppetdb-config|-c', help='puppetdb config file',
                        default='/etc/puppet/puppetdb.conf', dest='puppetdb_config')
    parser.add_argument('--base-path|-b', help='base path for the generated certs',
                        default='/srv/private/modules/secret/secrets/mcrouter/',
                        dest='base_path')
    parser.add_argument('--generate', help='Run cergen after having generated the files',
                        action='store_true')
    args = parser.parse_args()

    hosts = hosts_from_puppetdb(args.puppetdb_config)
    manifests_path = os.path.join(args.base_path, 'certificate.manifests.d')
    manifest_file = os.path.join(manifests_path, 'mediawiki-hosts.certs.yaml')
    manifest = cergen_manifests(hosts)
    with open(manifest_file, 'w') as fh:
        print('Writing the manifest to {}'.format(manifest_file))
        yaml.dump(manifest, fh)

    if args.generate:
        cergen_main(['--base-path', args.base_path, '--generate', manifests_path])
    else:
        print('IMPORTANT: add the definition of the mcrouter_ca.certs.yaml file')
        print(" in {}\n".format(manifests_path))
        print("You can now run cergen as follows:\n")
        print('cergen --base-path {} \\'.format(args.base_path))
        print("  --generate {}\n".format(manifests_path))
        print('This will generate and store all files into')
        print('{}/$hostname'.format(args.base_path))
