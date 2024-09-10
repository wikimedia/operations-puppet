#! /usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

# This script queries ferm::service and firewall::service resources for a given
# host in order to asses whether any ferm service definitions need to be converted
# to firewall::service definitions compatible with both worlds

from argparse import ArgumentParser
from pypuppetdb import connect


def get_args() -> None:
    """Parse arguments."""
    parser = ArgumentParser()
    parser.add_argument('host', help='The node to check')
    return parser.parse_args()


def query_resource(resource_type, node_name, pdb):

    pql = 'resources[title] {\n'
    pql += 'type = "' + resource_type + '" \n'
    pql += 'and nodes { certname = "' + node_name + '" }\n'
    pql += '}'

    results = pdb.pql(pql)
    # The nftables Puppet code normalises "-" and "." towards "_":
    return {r['title'].replace("-", "_").replace(".", "_") for r in results}


def run_checks():

    args = get_args()
    pdb_connection = connect()

    firewall_services = query_resource('Firewall::Service', args.host, pdb_connection)
    ferm_services = query_resource('Ferm::Service', args.host, pdb_connection)
    ferm_rules = query_resource('Ferm::Rule', args.host, pdb_connection)
    ferm_confs = query_resource('Ferm::Conf', args.host, pdb_connection)

    # 'filter_log_filter-bootp': Filters bootp/installation traffic from logs
    # 'log_everything'         : Default logging rule for ferm
    expected_ferm_rules = {'filter_log_filter_bootp', 'log_everything', 'dscp_default'}

    # Those are the standard Ferm rules and cluster definitions
    expected_ferm_confs = {'main', 'defs'}

    if 'drop_blocked_nets' in ferm_rules:
        print("Warning: This server uses defs_from_etcd, which isn't implemented for nft yet\n")
        expected_ferm_rules.add('drop_blocked_nets')

    if ferm_rules - expected_ferm_rules:
        print("The following Ferm rules need to be replaced with nftables::file definitions")
        print(ferm_rules - expected_ferm_rules)
        print()

    if ferm_confs - expected_ferm_confs:
        print("The following Ferm configs need to be replaced with nftables::file definitions")
        print(ferm_confs - expected_ferm_confs)
        print()

    if not ferm_services:
        print("This server appears to be already switched to nftables")
    else:
        if firewall_services == ferm_services:
            print("All firewall services are compatible with nftables. The full list is:")
            print(firewall_services)
        else:
            print("There are still some Ferm service defs to switch to firewall::service:")
            print(ferm_services - firewall_services)


if __name__ == '__main__':
    run_checks()
