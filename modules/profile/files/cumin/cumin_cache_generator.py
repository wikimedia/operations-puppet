#!/usr/bin/python
# Generate cache lists of hosts based on a list of queries to be used by Cumin
# with --backend direct in case of emergency when PuppetDB might not be available.

from __future__ import print_function

from datetime import datetime

import yaml

from ClusterShell.NodeSet import NodeSet

from cumin.query import QueryBuilder


CONFIG = '/etc/cumin/cache-generator.yaml'
CUMIN_CONFIG = '/etc/cumin/config.yaml'
OUTPUT_FILE_TEMPLATE = '/etc/cumin/host_lists/{name}.list'
BODY_TEMPLATE = "cumin --batch-size 25 --backend direct '{nodeset}'"
HEADER = """# Cache list of {name} hosts generated at {date} UTC with query: {query}
# To be used in case of emergency with cumin, if PuppetDB is not available:
# - adjust the batch size, if needed
# - add any other option you might need
# - add the command(s) to be executed at the end
"""


def update_hosts_list(cumin_config, name, query_string):
    query = QueryBuilder(query_string, cumin_config).build()
    hosts = query.execute()
    if not hosts:
        raise RuntimeError("Unable to get list of hosts for query {name}: '{query}'".format(
            name=name, query=query_string))

    with open(OUTPUT_FILE_TEMPLATE.format(name=name), 'w') as f:
        print(HEADER.format(name=name, query=query_string, date=datetime.utcnow()), file=f)
        print(BODY_TEMPLATE.format(nodeset=NodeSet.fromlist(hosts)), file=f)


if __name__ == '__main__':
    with open(CONFIG, 'r') as f:
        config = yaml.safe_load(f)

    with open(CUMIN_CONFIG, 'r') as f:
        cumin_config = yaml.safe_load(f)

    for query_name in config['queries']:
        update_hosts_list(cumin_config, query_name, config['queries'][query_name])
