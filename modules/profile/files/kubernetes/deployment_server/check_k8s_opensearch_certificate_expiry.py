#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
This script will measure and report the remaining amount of seconds before expiry
for the internal TLS certificate for each opensearch pod running in kubernetes.
"""

import argparse
import re
from datetime import datetime
from pathlib import Path

from kubernetes import client, config
from kubernetes.stream import stream
from prometheus_client import Gauge, CollectorRegistry, write_to_textfile

KUBECONFIGS_DIR = Path("/etc/kubernetes")

opensearch_kubeconfigs = KUBECONFIGS_DIR.glob("opensearch-*-deploy-*.config")


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--outfile", type=Path, metavar="FILE.prom", help="Output file", required=True
    )
    return parser.parse_args()


def get_cert_expiry(pod_name, namespace):
    """Exec into pod and get certificate expiry date using openssl."""
    exec_command = [
        "/bin/sh",
        "-c",
        "openssl x509 -enddate -noout -in /usr/share/opensearch/config/tls-http/tls.crt",
    ]
    resp = stream(
        client.CoreV1Api().connect_get_namespaced_pod_exec,
        pod_name,
        namespace,
        command=exec_command,
        stderr=True,
        stdin=False,
        stdout=True,
        tty=False,
        _preload_content=False,
    )
    output = ""
    while resp.is_open():
        resp.update(timeout=1)
        if resp.peek_stdout():
            output += resp.read_stdout()
        if resp.peek_stderr():
            print("STDERR:", resp.read_stderr())
        if not resp.is_open():
            break
    output = output.strip()
    match = re.search(r"notAfter=(\w+\s+\d+\s+\d+:\d+:\d+\s+\d+\s+\w+)", output)
    expiry_str = match.group(1)
    return datetime.strptime(expiry_str, "%b %d %H:%M:%S %Y %Z")


def measure_pod_certificate_expiry(kubeconfig_path: Path, namespace: str) -> int:
    config.load_kube_config(config_file=str(kubeconfig_path))
    v1 = client.CoreV1Api()
    pods = v1.list_namespaced_pod(
        namespace, label_selector="opster.io/opensearch-nodepool=masters"
    )

    for pod in pods.items:
        pod_name = pod.metadata.name
        expiry = get_cert_expiry(pod_name, namespace)
        yield pod_name, (expiry - datetime.utcnow()).total_seconds()


def main():
    args = parse_args()
    registry = CollectorRegistry()
    CERT_EXPIRY_SECONDS = Gauge(
        "master_cert_expiry_seconds",
        "Remaining seconds until OpenSearch master certificate expiry",
        namespace="opensearch_k8s",
        registry=registry,
        labelnames=["kubernetes_cluster", "namespace", "pod"],
    )
    for kubeconfig_path in opensearch_kubeconfigs:
        if "-operator" in kubeconfig_path.name:
            continue
        opensearch_cluster, _, environment = kubeconfig_path.name.replace(
            ".config", ""
        ).partition("-deploy-")

        print(kubeconfig_path)
        print(f"{environment}/{opensearch_cluster}")
        try:
            for pod_name, remaining_seconds in measure_pod_certificate_expiry(
                kubeconfig_path=kubeconfig_path, namespace=opensearch_cluster
            ):
                CERT_EXPIRY_SECONDS.labels(
                    kubernetes_cluster=environment,
                    namespace=opensearch_cluster,
                    pod=pod_name,
                ).set(remaining_seconds)
        except client.exceptions.ApiException:
            pass
    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    main()
