#!/usr/bin/env python3
"""Proxy access to PuppetDB facts.

Provides an extremely thin filtering proxy API for querying fact lists
from PuppetDB for external integration.
"""

import requests

from flask import Flask, abort, jsonify

# Allowed Facts
WHITELIST = [
    "serialnumber",
    "is_virtual",
    "productname",
    "manufacturer",
    "interfaces",
    "networking",
    "net_driver",
    "lldp",
]

# PuppetDB api URL template
PUPPETDB_URL = "http://localhost:8080/pdb/query/v4/facts/{fact}"

app = Flask(__name__)


@app.route("/v1/facts/<fact_name>")
def fact(fact_name):
    """Primary api endpoint.

    Accepts a single fact name and returns a dict of {hostname: value}.

    'hostname' will only be the unique local host part.
    """

    if fact_name not in WHITELIST:
        abort(403)

    results = requests.get(PUPPETDB_URL.format(fact=fact_name))
    if results.status_code != 200:
        abort(results.status_code)

    facts = {}
    for res in results.json():
        value = res["value"]
        if value == "Not Specified":
            value = None

        hostname = res["certname"].split(".", 1)[0]
        facts[hostname] = value

    return jsonify(facts)


@app.route("/v1/facts/<fact_name>/<host_name>")
def host_fact(fact_name, host_name):
    """Retrieve a fact for a specific host

    Accepts a single fact name and host name (in short form)
    and returns the fact as a JSON value.
    """

    if fact_name not in WHITELIST:
        abort(403)

    pdb_query = {"query": ["~", "certname", "^{}\\.".format(str(host_name))]}
    results = requests.post(PUPPETDB_URL.format(fact=fact_name), json=pdb_query)
    if results.status_code != 200:
        abort(results.status_code)

    res = results.json()
    if (len(res) == 1):
        result_value = res[0]["value"]
        if result_value == "Not Specified":
            result_value = None
    else:
        abort(404)

    return jsonify(result_value)
