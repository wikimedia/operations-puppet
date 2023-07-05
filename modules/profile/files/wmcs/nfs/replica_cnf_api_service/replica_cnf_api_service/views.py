#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import configparser
import io
import os
import subprocess
from hashlib import sha1
from pathlib import Path

import yaml
from flask import Blueprint, Flask, current_app, jsonify, request

bp_v1 = Blueprint("replica_cnf", __name__, url_prefix="/v1")
DRY_RUN_USERNAME = "dry.run.username"
DRY_RUN_PASSWORD = "dry.run.password"


def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__)

    if test_config is None:
        # load the instance config, if it exists, when not testing
        try:
            with open("/etc/replica_cnf_config.yaml") as file:
                config = yaml.safe_load(file)
            app.config.update(**config)
        except Exception:  # pylint: disable=broad-except
            pass  # ignore if file doesn't exist so unit tests can pass
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    app.register_blueprint(bp_v1)

    return app


def get_command_array(script):
    full_path = str(Path(current_app.config.get("SCRIPTS_PATH")) / script)
    if current_app.config.get("USE_SUDO", False):
        return ["sudo", full_path]
    else:
        return [full_path]


def mysql_hash(password):
    """
    Hash a password to mimic MySQL's PASSWORD() function
    """
    return "*" + sha1(sha1(password.encode("utf-8")).digest()).hexdigest()


def get_relative_path(account_type, name):
    """
    Return relative path to use for replica.my.cnf for a tool or user
    """
    if account_type == "tool":
        return str(
            # flake8: noqa
            Path(name[len(current_app.config.get("TOOLS_PROJECT_PREFIX")) + 1 :])
            / "replica.my.cnf"
        )
    elif account_type == "paws":
        return str(Path(name) / ".my.cnf")
    elif account_type == "user":
        return str(Path(name) / "replica.my.cnf")


def get_replica_path(account_type, relative_path):
    if account_type == "tool":
        base_dir = current_app.config.get("TOOL_REPLICA_CNF_PATH")
    elif account_type == "paws":
        base_dir = current_app.config.get("PAWS_REPLICA_CNF_PATH")
    elif account_type == "user":
        base_dir = current_app.config.get("USER_REPLICA_CNF_PATH")

    return str(Path(base_dir) / relative_path)


@bp_v1.route("/write-replica-cnf", methods=["POST"])
def write_replica_cnf():
    """
    Write a replica.my.cnf file.
    Will also set the 'immutable' attribute on the file, so users
    can not damage their own replica.my.cnf files accidentally.
    """
    request_data = request.get_json()
    account_id = request_data["account_id"]
    account_type = request_data["account_type"]
    uid = request_data["uid"]
    mysql_username = request_data["mysql_username"]
    pwd = request_data["password"]
    dry_run = request_data["dry_run"]

    relative_path = get_relative_path(account_type, account_id)
    replica_path = get_replica_path(account_type, relative_path)

    if dry_run:  # do not attempt to write replica.my.cnf file to replica_path if dry_run is True
        return jsonify({"result": "ok", "detail": {"replica_path": replica_path}}), 200

    # if a homedir for this account does not exist yet, just ignore
    # it home directory creation (for tools) is currently handled by
    # maintain-kubeusers, and we do not want to race. Tool accounts
    # that get passed over like this will be picked up on the next
    # round
    if account_type == "tool" and not Path(replica_path).parent.exists():
        return (
            jsonify(
                {
                    "result": "skip",
                    "detail": {
                        "replica_path": replica_path,
                        "reason": (
                            "Skipping Account {0}: Parent directory ({1}) does not exist yet, "
                            "this might happen if maintain-kubeusers has not yet created it, "
                            "skipping to retry in the next run"
                        ).format(account_id, str(Path(replica_path).parent)),
                    },
                }
            ),
            200,
        )

    if account_type == "user" and not Path(replica_path).parent.exists():
        return (
            jsonify(
                {
                    "result": "skip",
                    "detail": {
                        "replica_path": replica_path,
                        "reason": (
                            "Skipping Account {0}: Parent directory ({1}) does not exist yet, "
                            "this might happen if the user has not logged in yet, "
                            "skipping to retry in the next run"
                        ).format(account_id, str(Path(replica_path).parent)),
                    },
                }
            ),
            200,
        )

    # ignore if path aready exists
    if os.path.exists(replica_path):
        current_app.logger.warning("Configuration file %s already exists", replica_path)
        return (
            jsonify(
                {
                    "result": "skip",
                    "detail": {
                        "replica_path": replica_path,
                        "reason": "Skipping Account {0}: {1} Already exists".format(
                            account_id, replica_path
                        ),
                    },
                }
            ),
            200,
        )

    replica_config = configparser.ConfigParser()
    replica_config["client"] = {"user": mysql_username, "password": pwd}

    # Because ConfigParser can only write to a file
    # and not just return the value as a string directly
    replica_buffer = io.StringIO()
    replica_config.write(replica_buffer)

    res = subprocess.run(
        get_command_array(script="write_replica_cnf.sh")
        + [
            str(uid),
            relative_path,
            replica_buffer.getvalue().encode("utf-8"),
            account_type,
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        # subprocess.run without check=True is used here to avoid arguments
        # including username and password from being unintentionally sent back to client on error
        check=False,
    )

    replica_path = res.stdout.decode("utf-8").strip() or replica_path
    stderr = res.stderr.decode("utf-8")

    if res.returncode == 0:
        current_app.logger.info("Created conf file at %s.", replica_path)
        return jsonify({"result": "ok", "detail": {"replica_path": replica_path}}), 200
    else:
        if os.path.exists(replica_path):
            subprocess.check_output(
                get_command_array(script="delete_replica_cnf.sh") + [relative_path, account_type]
            )

        current_app.logger.error("Failed to create conf file at %s: %s", replica_path, stderr)
        return jsonify({"result": "error", "detail": {"reason": stderr}}), 500


@bp_v1.route("/read-replica-cnf", methods=["POST"])
def read_replica_cnf():
    """
    Parse a given replica.my.cnf file.
    Returns a tuple of mysql username, password_hash
    """

    request_data = request.get_json()
    account_id = request_data["account_id"]
    account_type = request_data["account_type"]
    dry_run = request_data["dry_run"]

    relative_path = get_relative_path(account_type, account_id)

    if dry_run:  # return dummy username and password if dry_run is True
        detail = {"user": DRY_RUN_USERNAME, "password": mysql_hash(DRY_RUN_PASSWORD)}
        return jsonify({"result": "ok", "detail": detail}), 200

    cp = configparser.ConfigParser()

    try:
        res = subprocess.run(
            get_command_array(script="read_replica_cnf.sh") + [relative_path, account_type],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

        if res.returncode == 0:
            cp.read_string(res.stdout.decode("utf-8"))

            detail = {
                # sometimes these values have quotes around them
                "user": cp["client"]["user"].strip("'"),
                "password": mysql_hash(cp["client"]["password"].strip("'")),
            }

            return jsonify({"result": "ok", "detail": detail}), 200
        else:
            raise Exception(res.stderr.decode("utf-8"))

    except KeyError as err:  # the err variable is not descriptive enough for KeyError.
        # catch KeyError and add more context to the error response.
        return (
            jsonify(
                {
                    "result": "error",
                    "detail": {"reason": "key {0} doesn't exist in ConfigParser".format(str(err))},
                }
            ),
            500,
        )

    except Exception as err:
        return jsonify({"result": "error", "detail": {"reason": str(err)}}), 500


@bp_v1.route("/delete-replica-cnf", methods=["POST"])
def delete_replica_cnf():
    request_data = request.get_json()
    account_id = request_data["account_id"]
    account_type = request_data["account_type"]
    dry_run = request_data["dry_run"]

    relative_path = get_relative_path(account_type, account_id)
    replica_path = get_replica_path(account_type, relative_path)

    if dry_run:  # do not attempt to delete replica.my.cnf file in replica_path if dry_run is True
        return jsonify({"result": "ok", "detail": {"replica_path": replica_path}}), 200

    res = subprocess.run(
        get_command_array(script="delete_replica_cnf.sh") + [relative_path, account_type],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )

    if res.returncode == 0:
        return (
            jsonify(
                {
                    "result": "ok",
                    "detail": {"replica_path": res.stdout.decode("utf-8").strip()},
                }
            ),
            200,
        )
    else:
        return (
            jsonify({"result": "error", "detail": {"reason": res.stderr.decode("utf-8")}}),
            500,
        )


@bp_v1.route("/paws-uids", methods=["GET"])
def fetch_paws_uids():
    try:
        path = get_replica_path("paws", "")
        paws_ids = os.listdir(path)
        return jsonify({"result": "ok", "detail": {"paws_uids": paws_ids}}), 200
    except Exception as err:  # pylint: disable=broad-except
        return jsonify({"result": "error", "detail": {"reason": str(err)}}), 500


app = create_app()
