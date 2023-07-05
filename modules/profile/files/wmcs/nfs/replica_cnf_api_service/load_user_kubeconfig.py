#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import json
import os
import re
from dataclasses import asdict, replace
from functools import partial
from pathlib import Path

import click
import yaml
from toolforge_weld.kubernetes_config import Kubeconfig


def fix_path_on_nfs(mounted_path: Path, user: str, kube_path: str) -> str:
    """Resolve the path from the NFS server perspective.

    As we run on the nfs server, the path in the kubeconfig is not correct, as it references
    the path it would be mounted on by the nfs client.
    Example of fix:
        mounted_path=/path/to/userhome/.toolskube/some_cert.crt
        user=userhome
        kube_path=/srv/path/to/userhome/.kube/config

        result=/srv/path/to/userhome/.toolskube/some_cert.crt
    """
    server_base_path = re.sub(f"/{re.escape(user)}/.*", "", kube_path) + f"/{user}/"
    return re.sub(f".*/{re.escape(user)}/", server_base_path, str(mounted_path))


@click.command()
@click.argument("toolforge_user")
def main(toolforge_user=str):
    """
    This script load a kubeconfig and outputs a new one with all the files embedded in it.

    Used to read a user kubeconfig through sudo, parse it and return it to the invoker so they
    don't need direct access to the files involved.

    Note that we can't use `kubectl config view --flatten=true` as the paths for the certs are the
    ones for the mounted volumes, not from the nfs server

    Arguments:
        TOOLFORGE_USER: user to retrieve the kubeconfig for, without the prefix (ex. `test` instead
                        of `toolsbeta.test`).
    """
    config_path = os.getenv("CONF_FILE") or "/etc/replica_cnf_config.yaml"
    config = yaml.safe_load(Path(config_path).open())
    kubeconfig_path = config["BACKENDS"]["ToolforgeToolEnvvarsBackend"]["EnvvarsConfig"][
        "kubeconfig_path_template"
    ].format(user=toolforge_user)
    kubeconfig = Kubeconfig.load(path=Path(kubeconfig_path))

    fix_path = partial(fix_path_on_nfs, user=toolforge_user, kube_path=kubeconfig_path)
    client_cert_file = kubeconfig.client_cert_file
    client_key_file = kubeconfig.client_key_file
    client_cert_data = kubeconfig.client_cert_data
    client_key_data = kubeconfig.client_key_data
    if client_cert_file:
        client_cert_data = Path(fix_path(client_cert_file)).read_text()
    if client_key_file:
        client_key_data = Path(fix_path(client_key_file)).read_text()

    resolved_config = replace(
        kubeconfig,
        client_cert_data=client_cert_data,
        client_key_data=client_key_data,
        client_cert_file=None,
        client_key_file=None,
    )

    print(json.dumps(asdict(resolved_config)))


if __name__ == "__main__":
    main()
