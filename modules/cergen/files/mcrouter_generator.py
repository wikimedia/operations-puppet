#!/usr/bin/env python3
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
import socket
import yaml

from cergen.main import main as cergen_main


def hosts_from_puppetdb(configfile):
    c = configparser.ConfigParser()
    c.read(configfile)
    puppetdb_url = "{}/pdb/query/v4/resources".format(c['main']['server_urls'])
    r = requests.post(
        puppetdb_url,
        json={
            'query': [
                "and",
                ['=', 'type', 'Class'],
                ["=", "title", "Profile::Mediawiki::Mcrouter_wancache"]
            ]
        },
        verify=True)
    if r.status_code != requests.codes.ok:
        raise ValueError("Got non-OK status code from puppetdb: %d", r.status_code)
    hosts = set([el['certname'] for el in r.json()])
    if not len(hosts):
        raise ValueError('No hosts found, maybe the puppetdb query needs fixing?')
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
            'key_usage': ['digital_signature', 'content_commitment', 'key_encipherment']
        }

    return {name: definition_for(socket.gethostbyname(name)) for name in hosts}


def main():
    parser = argparse.ArgumentParser(description='generate the yaml files for cergen, then runs it')
    parser.add_argument('--puppetdb-config', '-c', help='puppetdb config file',
                        default='/etc/puppet/puppetdb.conf')
    parser.add_argument('--base-path', '-b',
                        help='base path for the generated certs',
                        default='/srv/private/modules/secret/secrets/mcrouter/')
    parser.add_argument('--manifests-path', '-m', help='The directory where to read manifests',
                        default='/etc/cergen/mcrouter.manifests.d')
    parser.add_argument('--generate', help='Run cergen after having generated the files',
                        action='store_true')
    parser.add_argument('--add',
                        help='List of hosts to add to the '
                        'generated manifest (for new installations)',
                        metavar='HOSTNAMES', nargs="+", default=None)
    args = parser.parse_args()
    hosts = hosts_from_puppetdb(args.puppetdb_config)
    if args.add is not None:
        hosts.extend(args.add)
    if not os.path.isdir(args.manifests_path):
        os.mkdir(args.manifests_path)
    manifest_file = os.path.join(args.manifests_path, 'mediawiki-hosts.certs.yaml')
    manifest = cergen_manifests(hosts)
    with open(manifest_file, 'w') as fh:
        print('Writing the manifest to {}'.format(manifest_file))
        yaml.dump(manifest, fh)

    if args.generate:
        cergen_main(['--base-path', args.base_path, '--generate', args.manifests_path])
    else:
        output_tpl = """
IMPORTANT: add the definition of the mcrouter_ca.certs.yaml in {base}.

Granted you did that, you can now run cergen as follows:

cergen --base-path {base} \
  --generate {manifests}

This will generate and store all files into
{base}
"""
        print(output_tpl.format(base=args.base_path, manifests=args.manifests_path))


if __name__ == '__main__':
    main()
