#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from flask import Flask, jsonify, request

app = Flask(__name__)


# Silly memory store
envvars = {}


@app.route("/healthz", methods=["GET"])
def healthz():
    return jsonify({"status": "ok"}), 200


@app.route("/envvars/v1/envvar/<varname>", methods=["GET"])
def getvar(varname):
    if varname in envvars:
        return jsonify(envvars[varname]), 200

    return jsonify({"message": f"{varname} not found"}), 404


@app.route("/envvars/v1/envvar/<varname>", methods=["DELETE"])
def delvar(varname):
    if varname in envvars:
        myvar = envvars[varname]
        del envvars[varname]
        return jsonify(myvar), 200

    return jsonify({"message": f"{varname} not found"}), 404


@app.route("/envvars/v1/envvar/<varname>", methods=["POST"])
def addvar(varname):
    data = request.get_json()
    envvars[varname] = {
        "name": varname,
        "value": data["value"],
    }

    return jsonify(envvars[varname]), 200


if __name__ == "__main__":
    app.run(port=8082)
