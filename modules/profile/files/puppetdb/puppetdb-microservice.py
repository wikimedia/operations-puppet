#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Proxy access to PuppetDB.

Provides a secure proxy to PuppetDB that exposes only non-sensitive
information so that can be opened to hosts that require PuppetDB
integration but the users that have access to that hosts should not
be able to fully access PuppetDB and get sensitive information.

This proxy is needed because of the lack of ACLs in PuppetDB and
because it's easier to implement than using the PuppetDB certificate
authentication via certificate-allowlist.

Allowed queries:

* The facts endpoint to gather whitelisted facts.
* The nodes and resources endpoints to enable Cumin's query, but
  returning only a subset of the actual object returned by PuppetDB
  In particular only the certname field is returned so that no
  sensitive information like class parameters are exposed to the
  caller.
"""
from json import loads

import requests

from flask import Flask, abort, jsonify, request

# Allowed Facts
FACTS_WHITELIST = [
    "serialnumber",
    "is_virtual",
    "productname",
    "manufacturer",
    "interfaces",
    "networking",
    "net_driver",
    "lldp",
]

PUPPETDB_BASE_URL = "http://localhost:8080/pdb/query/v4"

app = Flask(__name__)


def _puppetdb_request(*paths, json=None, redacted=False):
    """Make a request to PuppetDB, abort on error, return the results.

    All the given pats parameters will be joined with / to form the
    final URL to call.
    If the json parameter is present the request will be a POST, while
    if not present it will be a GET.
    If the redacted parameter is True only the certname of the matched
    objects is returned.
    """
    if redacted:
        # Sometimes json['query'] is a string other times its an object
        # possibly just my testing with curl
        query = loads(json['query']) if isinstance(json['query'], str) else json['query']
        json['query'] = [
            "extract",
            ["certname"],
            query,
            ["group_by", "certname"],
        ]
    url = '/'.join([PUPPETDB_BASE_URL, *paths])
    response = requests.post(url, json=json)

    if response.status_code != 200:
        abort(response.status_code)

    return response.json()


@app.route("/")
def health_check():
    """Call the /status/v1/services/puppetdb-status api and indicate if puppetdb is healthy."""
    url = 'http://localhost:8080/status/v1/services/puppetdb-status'
    result = requests.get(url)
    if result.status_code != 200:
        abort(result.status_code)
    result = result.json()
    status = result['status']
    if (
        result['state'] == 'running'
        and status['read_db_up?']
        and status['write_db_up?']
        and not status['maintenance_mode?']
    ):
        return jsonify({'status': 'OK'})
    return jsonify(result), 503


@app.route("/v1/facts/<fact_name>")
def fact(fact_name):
    """Accepts a single fact name and returns a dict of {hostname: value}.

    'hostname' will only be the unique local host part.
    """

    if fact_name not in FACTS_WHITELIST:
        abort(403)

    facts = {}
    for result in _puppetdb_request('facts', fact_name):
        value = result["value"]
        if value == "Not Specified":
            value = None

        hostname = result["certname"].split(".", 1)[0]
        facts[hostname] = value

    return jsonify(facts)


@app.route("/v1/facts/<fact_name>/<host_name>")
def host_fact(fact_name, host_name):
    """Retrieve a fact for a specific host.

    Accepts a single fact name and host name (in short form)
    and returns the fact as a JSON value.
    """

    if fact_name not in FACTS_WHITELIST:
        abort(403)

    pdb_query = {"query": ["~", "certname", "^{}\\.".format(host_name)]}
    results = _puppetdb_request('facts', fact_name, json=pdb_query)
    if len(results) == 1:
        result_value = results[0]["value"]
        if result_value == "Not Specified":
            result_value = None
    else:
        abort(404)

    return jsonify(result_value)


# ------------------------------------------------------------------
# Redacted proxy to PuppetDB API endpoints, URIs must be unmodified.
# ------------------------------------------------------------------


@app.route("/pdb/query/v4/nodes", methods=["POST"])
def nodes():
    """Nodes endpoint for POST requests.

    Accepts any POST query to the nodes endpoint, proxy it to PuppetDB and
    returns a list of simplified objects {'certname': 'hostname.example.com'}.
    """
    return jsonify(_puppetdb_request('nodes', json=request.json, redacted=True))


@app.route("/pdb/query/v4/resources", methods=["POST"])
def resources():
    """Resources endpoint for POST requests.

    Accepts any POST query to the resources endpoint, proxy it to PuppetDB and
    returns a list of simplified objects {'certname': 'hostname.example.com'}.
    """
    return jsonify(_puppetdb_request('resources', json=request.json, redacted=True))
