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
    return parser


def main():
    parser = parse_args()
    options = parser.parse_args()
    conn1 = WMFMariaDB(host=options.host1, database=options.database)
    conn2 = WMFMariaDB(host=options.host2, database=options.database)
    command = 'SELECT min({0}), max({0}) FROM {1}'.format(options.column, options.table)
    # print(command)
    result1 = conn1.execute(command=command, dryrun=False)
    if not result1['success']:
        print('Minimum and maximum ids could not be retrieved, exiting.')
        return
    min_id = result1['rows'][0][0]
    max_id = result1['rows'][0][1]
    command = 'DESCRIBE {}'.format(options.table)
    # print(command)
    result1 = conn1.execute(command=command, dryrun=False)
    if not result1['success']:
        print('Could not describe the table, exiting.')
        return
    all_columns = ','.join({"IFNULL(" + x[0] + ", 'NULL')" for x in result1['rows']})
    command = 'SET SESSION group_concat_max_len = {}'.format(options.group_concat_max_len)
    # print(command)
    conn1.execute(command=command, dryrun=False)
    conn2.execute(command=command, dryrun=False)
    differences = 0
    for lower_limit in range(min_id, max_id, options.step):
        upper_limit = lower_limit + options.step - 1
        if upper_limit > max_id:
            upper_limit = max_id

        command = 'SELECT crc32(GROUP_CONCAT({4})) FROM {0} WHERE {1} BETWEEN {2} AND {3} ORDER BY {1}'.format(options.table, options.column, lower_limit, upper_limit, all_columns)
        # print(command)
        result1 = conn1.execute(command=command, dryrun=False)
        result2 = conn2.execute(command=command, dryrun=False)
        if not(result1['success'] and result2['success'] and result1['rows'][0][0] == result2['rows'][0][0]):
            print('Rows are different WHERE {} BETWEEN {} AND {}'.format(options.column, lower_limit, upper_limit))
            differences = differences + 1

    if differences == 0:
        print("No differences found.")


if __name__ == "__main__":
    main()
