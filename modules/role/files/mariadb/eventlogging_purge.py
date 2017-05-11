from __future__ import print_function

import argparse
import csv
import logging
import os
import re
import sys


"""Parse a TSV file containing tables and their attributes to whitelist.
Returns a hashmap with the following format:
- each key is a table name
- each key is another hashmap that points to a list. If the list is None,
  it means that the attribute as a whole needs to be whitelisted. If not empty,
  it means that the target attribute contains a JSON structure and only some of
  its fields needs to be kept.
"""


def parse_whitelist_file(filepath):
    with open(filepath, 'r') as whitelist_fd:
        whitelist_lines = csv.reader(whitelist_fd, delimiter='\t')
        whitelist_hash = {}

        allowed_tablename_format = re.compile("^[A-Za-z0-9_]+")
        allowed_attribute_format = re.compile("^[A-Za-z0-9_\.]+"
                                              "(\[[a-z0-9_]+\])?$")
        for line in whitelist_lines:
            if len(line) != 2:
                raise RuntimeError('Error in the whitelist: too many elements'
                                   'per line')

            table_name = line[0].strip()
            attribute = line[1].strip()

            if not allowed_tablename_format.match(table_name):
                # TODO: better exception
                raise RuntimeError('Error in the whitelist: table name {} not'
                                   'following the allowed format (^[A-Za-z0-9_]+)'
                                   .format(table_name))

            if not allowed_attribute_format.match(attribute):
                # TODO: better exception
                raise RuntimeError('Error in the whitelist: attribute {} not'
                                   'following the allowed format (^[A-Za-z0-9_\.]+'
                                   '(\[[a-z0-9_]+\])?$)'.format(attribute))

            if table_name not in whitelist_hash:
                whitelist_hash[table_name] = {}

            attribute_prefix = attribute
            json_field = None
            if '[' in attribute:
                attribute_prefix = attribute.split('[')[0]
                json_field = attribute.split('[')[0].strip("]")

            if json_field is None:
                if attribute_prefix not in whitelist_hash[table_name].keys():
                    whitelist_hash[table_name][attribute_prefix] = None
                else:
                    raise RuntimeError('Error in the whitelist: attribute {}'
                                       'is listed multiple times or in mixed formats.'
                                       .format(attribute_prefix))
            else:
                if attribute_prefix not in whitelist_hash[table_name]:
                    whitelist_hash[table_name][attribute_prefix] = [json_field]
                elif len(whitelist_hash[table_name][attribute_prefix]) == 0:
                    raise RuntimeError('Error in the whitelist: attribute {}'
                                       'is listed multiple times or in mixed formats.'
                                       .format(attribute_prefix))
                else:
                    whitelist_hash[table_name][attribute_prefix].append(json_field)

    return whitelist_hash


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='EventLogging data retention script')
    parser.add_argument('dbhostname', help='The target db hostname to purge')
    parser.add_argument('--whitelist', default="whitelist.tsv",
                        help='The full path of the TSV whitelist file (default: whitelist.tsv)')
    parser.add_argument('--dbport', default=3306,
                        help='The target db port (default: 3306)')
    parser.add_argument('--dbname', default='log',
                        help='The EventLogging database name (default: log)')
    parser.add_argument('--retention', default=90,
                        help='Delete logs older than this number of days'
                        ' (default: 90)')
    args = parser.parse_args()

    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    log = logging.getLogger('main')

    # Args basic checks
    if not os.path.exists(args.whitelist):
        log.error('The whitelist filepath provided does not exist')
        exit(1)

    try:

        # Parse whitelist file and temporary printing the data structure
        # for debugging purposes
        from pprint import pprint
        whitelist = parse_whitelist_file(args.whitelist)
        pprint(whitelist)

        # Connect to the database
        # TODO: consider to use the following code
        # https://gerrit.wikimedia.org/r/#/c/338809/4/modules/role/files/mariadb/WMFMariaDB.py

        # Retrieve the list of tables
        # TODO

        # Apply the retention policy to each table
        # TODO

    except Exception as e:
        log.error(e)
        exit(1)
