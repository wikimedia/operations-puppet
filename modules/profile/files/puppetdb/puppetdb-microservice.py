#!/usr/bin/env python3
"""Proxy access to PuppetDB facts.

Provides an extremely thin filtering proxy API for querying fact lists
from PuppetDB for external validation.
"""

import requests

from flask import Flask, abort, jsonify

# Allowed Facts
WHITELIST = ["serialnumber"]

# PuppetDB api URL template
PUPPETDB_URL = "http://localhost:8080/pdb/query/v4/facts/{fact}"

app = Flask(__name__)


@app.route("/v1/factcheck/<fact_name>")
def factcheck(fact_name):
    """Primary api endpoint.

    Accepts a single fact name and returns a list of [hostname, value].
    """

    if fact_name not in WHITELIST:
        abort(403)

    results = requests.get(PUPPETDB_URL.format(fact=fact_name))
    if results.status_code != 200:
        abort(results.status_code)

    fact_list = []
    for fact in results.json():
        value = fact["value"]
        if value == "Not Specified":
            value = None
        fact_list.append((fact["certname"], value))

    return jsonify(fact_list)
