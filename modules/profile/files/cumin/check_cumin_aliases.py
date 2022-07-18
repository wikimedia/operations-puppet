#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Check Cumin aliases configuration file for inconsistencies.

Suitable to be used as a cron job, it will print no output if no inconsistency is found,
and other report the errors to correct.
"""
import time

from cumin import Config, NodeSet, query
from cumin.backends import InvalidQueryError


# Hardcoded DC aliases to verify them.
DCS = {'eqiad', 'codfw', 'esams', 'ulsfo', 'eqsin', 'drmrs'}

# Aliases that are allowed to match zero hosts.
OPTIONAL_ALIASES = {'spare'}


def main():
    """Check Cumin aliases for inconsistencies.

    Note:
    Those are the performed checks
      - each alias should return some hosts, unless listed in OPTIONAL_ALIASES.
      - the sum of all DC-related aliases should return all hosts.
      - the sum of all the other aliases should return all hosts.

    """
    config = Config()
    dc_hosts = NodeSet()
    alias_hosts = NodeSet()
    all_hosts = query.Query(config).execute('*')
    return_code = 0

    for alias in config['aliases']:
        try:
            match = query.Query(config).execute('A:' + alias)
        except InvalidQueryError as error:
            print('Unable to execute query for alias {alias}: {msg}'.format(alias=alias, msg=error))
            return_code = 1
            continue

        if not match and alias not in OPTIONAL_ALIASES:
            print('Alias {alias} matched 0 hosts'.format(alias=alias))
            return_code = 1

        if alias in DCS:
            dc_hosts |= match
        else:
            alias_hosts |= match

        time.sleep(2)  # Go gentle on PuppetDB

    for hosts, name in ((dc_hosts, 'DC'), (alias_hosts, 'Other')):
        if all_hosts - hosts:
            print('{name} aliases do not cover all hosts: {hosts}'.format(
                name=name, hosts=(all_hosts - hosts)))
            return_code = 1
        elif dc_hosts - all_hosts:
            print('{name} aliases have unknown hosts: {hosts}'.format(
                name=name, hosts=(hosts - all_hosts)))
            return_code = 1

    return return_code


if __name__ == '__main__':
    raise SystemExit(main())
