#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Managed by Puppet (puppet:///modules/profile/toolforge/bastion/migrate-index.py)

import argparse
import getpass
import json
import sys

import requests
from toolforge_weld.api_client import ToolforgeClient, ToolforgeKubernetesConfigError
from toolforge_weld.kubernetes_config import Kubeconfig

OLD_CLUSTER = "http://elasticsearch.svc.tools.eqiad1.wikimedia.cloud:80"
NEW_CLUSTER = "http://opensearch.svc.tools.eqiad1.wikimedia.cloud:80"
TOOLFORGE_API_ENDPOINT = "https://api.svc.tools.eqiad1.wikimedia.cloud:30003"

USER_AGENT = "opensearch migrate-index.py"


def main():
    parser = argparse.ArgumentParser(description="""
Utility to migrate data from the old Elasticsearch to the new OpenSearch cluster

This script will migrate the specified index(es) from the old ES cluster to the new
one. Index replication settings, aliases, and mappings will be copied over.

By default, the username and password stored in the TOOL_ELASTICSEARCH_USER and
TOOL_ELASTICSEARCH_PASSWORD environment variables are used. If those variables are
not set, for example because the setup in your tool pre-dates the envvars
functionality, the authentication settings will be prompted on the terminal.
""")
    parser.add_argument("index", help="name of the index to migrate", nargs="+")
    parser.add_argument(
        "--username",
        required=False,
        help="username to authenticate to the cluster with",
    )
    parser.add_argument(
        "--password-stdin",
        required=False,
        action="store_true",
        help="read password directly from standard input",
    )
    args = parser.parse_args()

    envvars = {}
    try:
        kubeconfig = Kubeconfig.load()
        tool_name = kubeconfig.current_namespace.removeprefix("tool-")
        tf_client = ToolforgeClient(
            server=TOOLFORGE_API_ENDPOINT,
            kubeconfig=kubeconfig,
            user_agent=USER_AGENT,
        )
        envvars = {
            entry["name"]: entry["value"]
            for entry in tf_client.get(f"/envvars/v1/tool/{tool_name}/envvars")[
                "envvars"
            ]
        }
    except ToolforgeKubernetesConfigError:
        # ignore, for example when running as a normal user
        pass

    username = args.username
    if not username:
        username = envvars.get("TOOL_ELASTICSEARCH_USER")
    if not username:
        username = input("Username: ")

    password = None
    if args.password_stdin:
        password = sys.stdin.read().strip()
    if not password:
        password = envvars.get("TOOL_ELASTICSEARCH_PASSWORD")
    if not password:
        password = getpass.getpass("Password: ")

    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})
    session.auth = (username, password)

    for index in args.index:
        if session.head(f"{OLD_CLUSTER}/{index}").status_code != 200:
            print(f"Index {index} does not exist on the old cluster", file=sys.stderr)
            sys.exit(1)
        if session.head(f"{NEW_CLUSTER}/{index}").status_code != 404:
            print(f"Index {index} already exists on the new cluster", file=sys.stderr)
            sys.exit(1)

    for index in args.index:
        index_data = session.get(f"{OLD_CLUSTER}/{index}").json()[index]
        index_settings = index_data.get("settings", {}).get("index", {})

        response = session.put(
            f"{NEW_CLUSTER}/{index}",
            json={
                # https://docs.opensearch.org/latest/api-reference/index-apis/create-index/
                "settings": {
                    "index": {
                        "number_of_shards": index_settings.get("number_of_shards", 1),
                        "number_of_replicas": index_settings.get(
                            "number_of_replicas", 1
                        ),
                    }
                },
                "mappings": index_data.get("mappings", {}),
                "aliases": index_data.get("aliases"),
            },
        )

        response = session.post(
            f"{NEW_CLUSTER}/_reindex",
            json={
                # https://docs.opensearch.org/latest/api-reference/document-apis/reindex/
                "source": {
                    "remote": {
                        "host": OLD_CLUSTER,
                        "username": username,
                        "password": password,
                    },
                    "index": index,
                    # this is a batch size, not the total number of records to move
                    "size": 2500,
                },
                "dest": {
                    "index": index,
                },
            },
        )
        print(index, json.dumps(response.json()))


if __name__ == "__main__":
    main()
