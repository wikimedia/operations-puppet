#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from flask import Flask, jsonify, request

app = Flask(__name__)


# Silly memory store
envvars = {}


@app.route("/healthz", methods=["GET"])
def healthz():
    return jsonify({"status": "ok"}), 200


@app.route("/envvars/v1/tool/<toolname>/envvar/<varname>", methods=["GET"])
def getvar(toolname, varname):
    if varname in envvars:
        return (
            jsonify(
                {"messages": {"info": [], "warning": [], "error": []}, "envvar": envvars[varname]}
            ),
            200,
        )

    return jsonify({"messages": {"error": [f"GET: {varname} not found"]}}), 404


@app.route("/envvars/v1/tool/<toolname>/envvar/<varname>", methods=["DELETE"])
def delvar(toolname, varname):
    if varname in envvars:
        myvar = envvars[varname]
        del envvars[varname]
        return jsonify(myvar), 200

    return jsonify({"messages": {"error": [f"DELETE: {varname} not found"]}}), 404


@app.route("/envvars/v1/tool/<toolname>/envvar", methods=["POST"])
def addvar(toolname):
    data = request.get_json()

    name = data.get("name")
    value = data.get("value")

    envvars[name] = {
        "name": name,
        "value": value,
    }
    response = {
        "envvar": envvars[name],
        "messages": {
            "info": [],
            "warning": [],
            "error": [],
        },
    }

    return jsonify(response), 200


if __name__ == "__main__":
    app.run(port=8082)
