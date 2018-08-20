#!/usr/bin/env python3
"""Check Cumin aliases configuration file for inconsistencies.

Suitable to be used as a cron job, it will exit with zero exit code and doesn't produce any output
if no inconsistency is found, with a positive integer printing the differences on error.
"""
import time
import sys

from cumin import Config, NodeSet, query


# Hardcoded DC aliases to verify them.
DCS = ('eqiad', 'codfw', 'esams', 'ulsfo', 'eqsin')


def main():
    """Check Cumin aliases for inconsistencies.

    Note:
    Those are the performed checks
      - each alias should return some hosts.
      - the sum of all DC-related aliases should return all hosts.
      - the sum of all the other aliases should return all hosts.

    Returns:
        int: zero on success, positive integer on failure.

    """
    ret = 0
    config = Config()
    dc_hosts = NodeSet()
    alias_hosts = NodeSet()
    all_hosts = query.Query(config).execute('*')

    for alias in config['aliases']:
        match = query.Query(config).execute('A:' + alias)
        if not match:
            print('Alias {alias} matched 0 hosts'.format(alias=alias))
            ret = 1

        if alias in DCS:
            dc_hosts |= match
        else:
            alias_hosts |= match

        time.sleep(2)  # Go gentle on PuppetDB

    base_ret = 2
    for hosts, name in ((dc_hosts, 'DC'), (alias_hosts, 'Other')):
        if all_hosts - hosts:
            print('{name} aliases do not cover all hosts: {hosts}'.format(
                name=name, hosts=(all_hosts - hosts)))
            ret += base_ret
        elif dc_hosts - all_hosts:
            print('{name} aliases have unknown hosts: {hosts}'.format(
                name=name, hosts=(hosts - all_hosts)))
            ret += base_ret * 2

        base_ret *= 4

    return ret


if __name__ == '__main__':
    sys.exit(main())
