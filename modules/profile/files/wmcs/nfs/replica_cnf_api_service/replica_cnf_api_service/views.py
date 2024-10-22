#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
from __future__ import annotations

import os
from typing import Any, Optional, Type

import yaml
from flask import Blueprint, Flask, Response, current_app, jsonify, request
from replica_cnf_api_service.backends.common import (
    Backend,
    BackendError,
    Config,
    ReplicaCnf,
    Skip,
    UserType,
    mysql_hash,
)
from replica_cnf_api_service.backends.envvars_backend import (
    EnvvarsConfig,
    ToolforgeToolEnvvarsBackend,
)
from replica_cnf_api_service.backends.file_backend import (
    FileConfig,
    PawsUserFileBackend,
    ToolforgeToolBackendConfig,
    ToolforgeToolFileBackend,
    ToolforgeUserFileBackend,
)

bp_v1 = Blueprint("replica_cnf", __name__, url_prefix="/v1")
DRY_RUN_USERNAME = "dry.run.username"
DRY_RUN_PASSWORD = "dry.run.password"
BACKEND_CONFIGS: dict[str, Type[Config]] = {
    "FileConfig": FileConfig,
    "ToolforgeToolBackendConfig": ToolforgeToolBackendConfig,
    "EnvvarsConfig": EnvvarsConfig,
}
BACKENDS = {
    "PawsUserFileBackend": PawsUserFileBackend,
    "ToolforgeToolFileBackend": ToolforgeToolFileBackend,
    "ToolforgeUserFileBackend": ToolforgeUserFileBackend,
    "ToolforgeToolEnvvarsBackend": ToolforgeToolEnvvarsBackend,
}


class ReplicaCnfApp(Flask):
    def set_backends(self, replica_cnf_backends: list[Backend]):
        self.replica_cnf_backends = replica_cnf_backends


def get_error_response(reason: str) -> tuple[Response, int]:
    return (
        jsonify(
            {
                "result": "error",
                "detail": {"reason": reason},
            }
        ),
        500,
    )


def get_ok_response(**details) -> tuple[Response, int]:
    return (
        jsonify(
            {
                "result": "ok",
                "detail": details,
            }
        ),
        200,
    )


def get_skip_response(**details) -> tuple[Response, int]:
    return (
        jsonify(
            {
                "result": "skip",
                "detail": details,
            }
        ),
        200,
    )


def get_bad_usertype_response(bad_account_type: str) -> tuple[Response, int]:
    return (
        jsonify(
            {
                "result": "error",
                "detail": {
                    "reason": (
                        f"Bad user type {bad_account_type}, supported ones: "
                        f"{[elem.value for elem in UserType]}"
                    )
                },
            }
        ),
        400,
    )


def load_backends(backend_spec: dict[str, dict[str, Any]]) -> list[Backend]:
    backends: list[Backend] = []
    for backend_name, config in backend_spec.items():
        if backend_name not in BACKENDS:
            raise ValueError(
                f"Unable to find backend {backend_name}, "
                f"known backends: {' ,'.join(BACKENDS.keys())}"
            )

        if len(config) > 1:
            raise ValueError(
                f"More than one config found for backend {backend_name}, "
                f"only one is supported: {config}"
            )

        parsed_config: None | Config = None
        for config_name, config_params in config.items():
            if config_name not in BACKEND_CONFIGS:
                raise ValueError(
                    f"Unable to find config {config_name}, "
                    f"known configs: {' ,'.join(BACKEND_CONFIGS.keys())}"
                )

            parsed_config = BACKEND_CONFIGS[config_name].from_yaml(**config_params)

        if parsed_config:
            backends.append(BACKENDS[backend_name](config=parsed_config))

    return backends


def create_app(test_config=None) -> ReplicaCnfApp:
    """
    The return value of this function servers also as entry point for uwsgi.
    """
    # create and configure the app
    app = ReplicaCnfApp(__name__)

    config = None
    if test_config is None:
        # load the instance config, if it exists, when not testing
        conf_file = os.getenv("CONF_FILE", "/etc/replica_cnf_config.yaml")
        try:
            with open(conf_file) as file:
                config = yaml.safe_load(file)

            app.config.update(**config)
        except Exception as error:  # pylint: disable=broad-except
            print(f"Error parsing config {conf_file}: {error}")
            raise
    else:
        # load the test config if passed in
        app.config.from_mapping(test_config)

    app.register_blueprint(bp_v1)
    if "BACKENDS" not in app.config:
        raise TypeError(
            f"Unable to find backends config, got (from file "
            f"{os.getenv('CONF_FILE', 'no custom file')}): {app.config}\n\n{config}"
        )

    app.set_backends(load_backends(backend_spec=app.config["BACKENDS"]))

    return app


def get_backends() -> list[Backend]:
    backends = getattr(current_app, "replica_cnf_backends", None)
    if backends is None:
        raise ValueError(
            "For some reason the app did not have any backends, did you create with `create_app`?"
        )

    return backends


@bp_v1.route("/write-replica-cnf", methods=["POST"])
def write_replica_cnf() -> tuple[Response, int]:
    """
    Write a replica.my.cnf file.
    Will also set the 'immutable' attribute on the file, so users
    can not damage their own replica.my.cnf files accidentally.
    """
    request_data = request.get_json()
    account_id = request_data["account_id"]

    try:
        account_type = UserType(request_data["account_type"])
    except ValueError:
        return get_bad_usertype_response(request_data["account_type"])

    try:
        uid = int(request_data["uid"])
    except ValueError:
        return get_error_response(
            reason=f"Bad uid format, expected a number, got {request_data['uid']}"
        )

    mysql_username = request_data["mysql_username"]
    pwd = request_data["password"]
    dry_run = request_data["dry_run"]

    replica_cnf = ReplicaCnf(
        user_type=account_type, user=account_id, db_user=mysql_username, db_password=pwd
    )

    results: dict[str, str] = {}
    has_error = False
    has_skipped = False
    for backend in get_backends():
        if not backend.handles_user_type(account_type):
            continue

        backend_key = backend.__class__.__name__
        try:
            new_replica_cnf = backend.save_replica_cnf(
                replica_cnf=replica_cnf,
                account_uid=uid,
                dry_run=dry_run,
            )
            current_app.logger.debug("Backend %s created ok", backend)
            results[backend_key] = (
                f"OK (user={new_replica_cnf.user}, db_user={new_replica_cnf.db_user})"
            )

        except Skip as skip:
            results[backend_key] = str(skip)
            has_skipped = True
            current_app.logger.debug("Backend %s skips: %s", backend, str(skip))

        except BackendError as error:
            results[backend_key] = str(error)
            has_error = True
            current_app.logger.debug(
                "Backend %s failed to create replica auth for %s: %s",
                backend,
                replica_cnf.user,
                error,
            )

    if not results:
        return get_error_response(
            reason=f"Unable to find a backend for user type {account_type.value}"
        )

    if has_error:
        return get_error_response(reason=f"Got errors: {' ,'.join(results.values())}")

    if has_skipped:
        return get_skip_response(
            reason=(
                "Some backends skipped:\n  "
                + "\n  ".join(f"{backend}:{result or 'OK'}" for backend, result in results.items())
            ),
        )

    if not results:
        return get_error_response(
            reason=f"Got error: none of the backend did actually create a file: {results}"
        )

    return get_ok_response(results=results)


@bp_v1.route("/read-replica-cnf", methods=["POST"])
def read_replica_cnf() -> tuple[Response, int]:
    """
    Parse a given replica.my.cnf file.
    Returns a tuple of mysql username, password_hash
    """

    request_data = request.get_json()
    account_id = request_data["account_id"]
    try:
        account_type = UserType(request_data["account_type"])
    except ValueError:
        return get_bad_usertype_response(request_data["account_type"])

    dry_run = request_data["dry_run"]

    replica_cnf: Optional[ReplicaCnf] = None
    prev_backend = None
    for backend in get_backends():
        if not backend.handles_user_type(UserType(account_type)):
            continue

        try:
            new_replica_cnf = backend.get_replica_cnf(
                user=account_id, dry_run=dry_run, user_type=account_type
            )
        except Skip as skip:
            current_app.logger.info("Skipping backend %s: %s", backend.__class__, str(skip))
            continue
        except Exception as error:
            current_app.logger.error(
                "Got error from backend %s: %s:%s", backend.__class__, error.__class__, str(error)
            )
            return get_error_response(reason=str(error))

        if not replica_cnf:
            replica_cnf = new_replica_cnf

        if replica_cnf != new_replica_cnf:
            return get_error_response(
                reason=(
                    "Different backends gave different replies: "
                    f"{replica_cnf} ({prev_backend.__class__.__name__}) != "
                    f"{new_replica_cnf} ({backend.__class__.__name__})"
                )
            )

        prev_backend = backend

    if replica_cnf is None:
        return get_error_response(reason=f"Unable to find a backend for user type {account_type}")

    return get_ok_response(user=replica_cnf.db_user, password=mysql_hash(replica_cnf.db_password))


@bp_v1.route("/delete-replica-cnf", methods=["POST"])
def delete_replica_cnf() -> tuple[Response, int]:
    request_data = request.get_json()
    account_id = request_data["account_id"]
    try:
        account_type = UserType(request_data["account_type"])
    except ValueError:
        return get_bad_usertype_response(request_data["account_type"])
    dry_run = request_data["dry_run"]

    results: dict[str, str] = {}
    for backend in get_backends():
        if not backend.handles_user_type(account_type):
            continue

        backend_key = backend.__class__.__name__
        try:
            backend.delete_replica_cnf(user=account_id, user_type=account_type, dry_run=dry_run)
            results[backend_key] = "OK"

        except Skip as skip:
            current_app.logger.info("Skipping backend %s: %s", backend.__class__, str(skip))
            continue

        except BackendError as error:
            return (
                jsonify({"result": "error", "detail": {"reason": str(error)}}),
                500,
            )

    if not results:
        return get_error_response(reason=f"Unable to find a backend for user type {account_type}")

    return get_ok_response(results=results)


@bp_v1.route("/paws-uids", methods=["GET"])
def fetch_paws_uids():
    try:
        path = current_app.config.get("PAWS_REPLICA_CNF_PATH")
        paws_ids = os.listdir(str(path))
        return get_ok_response(paws_uids=paws_ids)
    except Exception as err:  # pylint: disable=broad-except
        return get_error_response(reason=str(err))


if __name__ == "__main__":
    app = create_app()
    port = int(os.getenv("PORT", 8080))
    print(app.config)
    app.run(port=port)
