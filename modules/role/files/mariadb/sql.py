#!/usr/bin/env python3

from WMFMariaDB import WMFMariaDB

import argparse
# requires python3-tabulate
import tabulate


def parse_args():
    """
    Performs the parsing of execution parameters, and returns the object
    containing them
    """
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--host', '-h', help="""the hostname or dns to connect
                        to. Set it to "multi" to execute the same query on many
                        hosts, according to the shard and database parameters.
                        """, required=True)
    parser.add_argument('--execute', '-e', help='the sql command to execute',
                        required=True)
    parser.add_argument('--port', '-P', type=int, help='the port to connect',
                        default=3306)
    parser.add_argument('--dry-run', action='store_true', dest='dryrun',
                        help="""If to only run a test and only print what will
                             be done""")
    parser.add_argument('--no-dry-run', action='store_false', dest='dryrun',
                        help='If to really execute the given query')
    parser.add_argument('--shard', '-s', help="""Execute once on every host from
                        this shard. Set shard to "ALL" to execute it
                        cluster-wide. Can be refined further by setting a
                        database.""")
    parser.add_argument('--verbose', '-v', action='store_true', dest='debug',
                        help='Enable debug mode for execution trace.')
    parser.add_argument('--help', '-?', '-I', action='help',
                        help='show this help message and exit')
    parser.add_argument('database', nargs='?', default=None, help="""default
                        database to connect to (optional, by default it doesn't
                        change the default database). If the host is set as
                        'multi', a database can be set, and the query will be
                        sent to all hosts containing that wiki.""")
    parser.set_defaults(dryrun=True)
    parser.set_defaults(debug=False)
    return parser


def print_resultset(result, tablefmt="psql"):
    """
    Does a prety print of a result dictionary
    """
    print()
    print('Results for {}:{}/{}:'.format(result["host"], result["port"],
                                         result["database"]))
    if result is not None and result['success']:
        if result["numrows"] > 0:
            print(tabulate.tabulate(result["rows"], headers=result["fields"],
                                    tablefmt=tablefmt))
        if result["numrows"] != 1:
            row_word = 'rows'
        else:
            row_word = 'row'
        time = 0.00  # FIXME: Time is fake
        print('{} {} in set ({:.2f} sec)'.format(result["numrows"], row_word,
              time))
    else:
        print('ERROR: Error on connection or on query execution')


def main():
    parser = parse_args()
    options = parser.parse_args()

    if options.host == 'multi':
        result_list = WMFMariaDB.execute_many(command=options.execute,
                                              shard=options.shard,
                                              wiki=options.database,
                                              dryrun=options.dryrun,
                                              debug=options.debug)
        for result in result_list:
            print_resultset(result)
    elif options.shard is not None:
            print("ERROR: Shard cannot be set if host is not set to 'multi'.")
            result = None
    else:
        conn = WMFMariaDB(host=options.host, port=options.port,
                          database=options.database, debug=options.debug)
        if conn.connection is None:
            print('ERROR: Could not connect to {}'.format(options.host))
            return
        result = conn.execute(command=options.execute, dryrun=options.dryrun)
        conn.disconnect()
        print_resultset(result)


if __name__ == "__main__":
    main()
