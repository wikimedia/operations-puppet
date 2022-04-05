#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import configparser
import io
import os
import subprocess
from hashlib import sha1
from types import ModuleType
from typing import Any, Dict, Optional

from flask import Blueprint, Flask, current_app, request

bp_v1: ModuleType = Blueprint("replica_cnf", __name__, url_prefix="/v1")


def create_app(test_config: Optional[Dict] = None) -> ModuleType:
    # create and configure the app
    app: ModuleType = Flask(__name__, instance_relative_config=True)

    if test_config is None:
        # load the instance config, if it exists, when not testing
        app.config.from_pyfile("config.py", silent=True)
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    # ensure the instance folder exists
    os.makedirs(app.instance_path, exist_ok=True)

    app.register_blueprint(bp_v1)

    return app


def mysql_hash(password: str) -> str:
    """
    Hash a password to mimic MySQL's PASSWORD() function
    """
    return "*" + sha1(sha1(password.encode("utf-8")).digest()).hexdigest()


def get_replica_path(account_type: str, name: str) -> str:
    """
    Return path to use for replica.my.cnf for a tool or user
    """
    if account_type == "tool":
        return os.path.join(current_app.config["TOOLS_REPLICA_CNF_PATH"], name, "replica.my.cnf")
    elif account_type == "paws":
        return os.path.join(current_app.config["PAWS_REPLICA_CNF_PATH"], name, ".my.cnf")
    else:
        return os.path.join(current_app.config["OTHERS_REPLICA_CNF_PATH"], name, "replica.my.cnf")


@bp_v1.route("/fetch-replica-path", methods=["POST"])
def fetch_replica_path() -> Dict[str, Any]:

    request_data: Dict[str, Any] = request.json
    account_id: str = request_data["account_id"]
    account_type: str = request_data["account_type"]

    try:

        replica_path: str = get_replica_path(account_type, account_id)

        response_data: Dict[str, Any] = {"result": "ok", "detail": {"replica_path": replica_path}}

    except Exception as e:

        response_data: Dict[str, Any] = {"result": "error", "detail": {"reason": str(e)}}

    return response_data


@bp_v1.route("/write-replica-cnf", methods=["POST"])
def write_replica_cnf() -> Dict[str, Any]:
    """
    Write a replica.my.cnf file.

    Will also set the 'immutable' attribute on the file, so users
    can not damage their own replica.my.cnf files accidentally.
    """

    request_data: Dict[str, Any] = request.json
    account_id: str = request_data["account_id"]
    account_type: str = request_data["account_type"]
    uid: int = request_data["uid"]
    mysql_username: str = request_data["mysql_username"]
    pwd: str = request_data["password"]
    replica_path: str = get_replica_path(account_type, account_id)

    replica_config = configparser.ConfigParser()
    replica_config["client"] = {"user": mysql_username, "password": pwd}

    # Because ConfigParser can only write to a file
    # and not just return the value as a string directly
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    c_file = os.open(replica_path, os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW)
    try:
        os.write(c_file, replica_buffer.getvalue().encode("utf-8"))
        # uid == gid
        os.fchown(c_file, uid, uid)
        os.fchmod(c_file, 0o400)

        # Prevent removal or modification of the credentials file by users
        subprocess.check_output(["/usr/bin/chattr", "+i", replica_path])
    except Exception as e:
        os.remove(replica_path)
        response_data: Dict[str, Any] = {"result": "error", "detail": {"reason": str(e)}}
    finally:
        os.close(c_file)

    response_data: Dict[str, Any] = {"result": "ok", "detail": {"replica_path": replica_path}}
    return response_data


@bp_v1.route("/read-replica-cnf", methods=["POST"])
def read_replica_cnf() -> Dict[str, Any]:
    """
    Parse a given replica.my.cnf file

    Return a tuple of mysql username, password_hash
    """

    request_data: Dict[str, Any] = request.json
    account_id: str = request_data["account_id"]
    account_type: str = request_data["account_type"]
    replica_path: str = get_replica_path(account_type, account_id)

    cp = configparser.ConfigParser()
    cp.read(replica_path)

    try:

        detail: Dict[str, str] = {
            # sometimes these values have quotes around them
            "user": cp["client"]["user"].strip("'"),
            "password": mysql_hash(cp["client"]["password"].strip("'")),
        }

        response_data: Dict[str, Any] = {"result": "ok", "detail": detail}

    except Exception as e:

        response_data: Dict[str, Any] = {"result": "error", "detail": {"reason": str(e)}}

    return response_data


app: ModuleType = create_app()
