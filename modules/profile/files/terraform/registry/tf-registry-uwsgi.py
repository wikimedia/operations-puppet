#!/usr/bin/python3
# SPDX-License-Identifier: MIT
"""
This is a fork of https://github.com/caramelomartins/rekisteri,
licensed under the terms of the MIT license.

Copyright (c) 2020 Hugo Martins
Copyright (c) 2022 Taavi Väänänen

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import json
from pathlib import Path

from flask import Flask, abort, redirect

CONFIG_LOCATION = Path("/srv/terraform-registry/config")

app = Flask(__name__)


@app.route("/")
def index():
    return redirect("https://wikitech.wikimedia.org/wiki/User:Majavah/Terraform")


@app.route("/.well-known/terraform.json", methods=["GET"])
def discovery():
    return {
        "providers.v1": "/registry/v1/providers/",
    }


@app.route("/registry/v1/providers/registry/<name>/versions", methods=["GET"])
def versions(name):
    path = CONFIG_LOCATION / "providers" / f"{name}.json"

    if not path.exists():
        abort(404)

    with path.open("r") as reader:
        data = json.load(reader)

    response = {
        "versions": [],
    }

    for elem in data["versions"]:
        version = {
            "version": elem["version"],
            "protocols": elem["protocols"],
            "platforms": [],
        }

        for platform in elem["platforms"]:
            version["platforms"].append(
                {"os": platform["os"], "arch": platform["arch"]}
            )

        response["versions"].append(version)

    return response


@app.route(
    "/registry/v1/providers/registry/<name>/<version>/download/<os>/<arch>",
    methods=["GET"],
)
def package(name, version, os, arch):
    path = CONFIG_LOCATION / "providers" / f"{name}.json"

    if not path.exists():
        abort(404)

    with path.open("r") as reader:
        data = json.load(reader)

    provider = None

    for elem in data["versions"]:
        if elem["version"] == version:
            for platform in elem["platforms"]:
                if platform["os"] == os and platform["arch"] == arch:
                    provider = platform
                    provider["protocols"] = elem["protocols"]

    if provider is None:
        abort(404)

    return provider
