#!/usr/bin/env python3
from WMFMariaDB import WMFMariaDB

import argparse


def parse_args():
    """
    Performs the parsing of execution parameters, and returns the object
    containing them
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('host1')
    parser.add_argument('host2')
    parser.add_argument('database')
    parser.add_argument('table')
    parser.add_argument('column')
    parser.add_argument('--step', type=int, default=1000)
    parser.add_argument('--group_concat_max_len', type=int, default=10000000)
    parser.add_argument('--from-value', type=int, dest='from_value')
    parser.add_argument('--to-value', type=int, dest='to_value')
    parser.add_argument('--order-by', dest='order_by')
    parser.add_argument('--verbose', dest='verbose', action='store_true')
    return parser

def connect(host, database):
    if ':' in host:
        # we do not support ipv6 yet
        host, port = host1.split(':')
    else:
        host = options.host
        port = 3306
    return WMFMariaDB(host=host, database=database)

def main():
    parser = parse_args()
    options = parser.parse_args()
    conn1 = connect(options.host1, options.database)

    conn2 = connect(options.host2, options.database)

    command = 'SELECT min({0}) FROM {1}'.format(options.column, options.table)
    if options.verbose:
        print(command)
    result = conn1.execute(command=command, dryrun=False)
    if not result['success']:
        print('Minimum id could not be retrieved, exiting.')
        return
    min_id = result['rows'][0][0]

    command = 'SELECT max({0}) FROM {1}'.format(options.column, options.table)
    if options.verbose:
        print(command)
    result = conn1.execute(command=command, dryrun=False)
    if not result['success']:
        print('Maximum id could not be retrieved, exiting.')
        return
    max_id = result['rows'][0][0]

    if max_id is None or min_id is None:
        print('No rows found on the original table, exiting.')
        return
    if options.from_value is not None and options.from_value > min_id:
        min_id = options.from_value

    if options.to_value is not None and options.to_value < max_id:
        max_id = options.to_value

    command = 'DESCRIBE {}'.format(options.table)
    if options.verbose:
        print(command)
    result1 = conn1.execute(command=command, dryrun=False)
    if not result1['success']:
        print('Could not describe the table, exiting.')
        return
    all_columns = ','.join({"IFNULL(" + x[0] + ", 'NULL')" for x in result1['rows']})
    if options.order_by is None or options.order_by == '':
        order_by = options.column
    else:
        order_by = options.order_by
    command = 'SET SESSION group_concat_max_len = {}'.format(options.group_concat_max_len)
    if options.verbose:
        print(command)
    conn1.execute(command=command, dryrun=False)
    conn2.execute(command=command, dryrun=False)
    differences = 0
    for lower_limit in range(min_id, max_id, options.step):
        upper_limit = lower_limit + options.step - 1
        if upper_limit > max_id:
            upper_limit = max_id

        command = 'SELECT crc32(GROUP_CONCAT({4})) FROM {0} WHERE {1} BETWEEN {2} AND {3} ORDER BY {5}'.format(options.table, options.column, lower_limit, upper_limit, all_columns, order_by)
        if options.verbose:
            print(command)
        result1 = conn1.execute(command=command, dryrun=False)
        result2 = conn2.execute(command=command, dryrun=False)
        if not(result1['success'] and result2['success'] and result1['rows'][0][0] == result2['rows'][0][0]):
            print('Rows are different WHERE {} BETWEEN {} AND {}'.format(options.column, lower_limit, upper_limit))
            differences = differences + 1

    if differences == 0:
        print("No differences found.")


if __name__ == "__main__":
    main()
