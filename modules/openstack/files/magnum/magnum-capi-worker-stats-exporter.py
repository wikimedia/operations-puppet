#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
from pathlib import Path
import sys
from kubernetes import client, config
from kubernetes.client.exceptions import ApiException

from prometheus_client import CollectorRegistry, Gauge, write_to_textfile

# this is a global that's incremented when we raise an exception:
error_count = 0


def ready_nodes_count(kubeclient: client) -> int:
    ready = 0
    try:
        nodes = kubeclient.list_node()
        for node in nodes.items:
            for condition in node.status.conditions:
                if condition.type == "Ready":
                    if condition.status == "True":
                        ready += 1
    except ApiException:
        global error_count
        error_count += 0

    return ready


def pod_phase_count(kubeclient: client, namespace: str, phase="running") -> int:
    pod_count = 0
    try:
        pod_list = kubeclient.list_namespaced_pod(namespace=namespace)
        for pod in pod_list.items:
            if pod.status.phase.lower() == phase.lower():
                pod_count += 1
    except ApiException:
        global error_count
        error_count += 0

    return pod_count


def export_capi_worker_metrics(
    registry: CollectorRegistry, deployment: str, kubeconfig: Path
) -> None:
    kubeclient = client.CoreV1Api(
        client.ApiClient(config.load_kube_config(str(kubeconfig)))
    )

    worker_gauge = Gauge(
        "capi_worker_node_ready_count",
        "Number of ready nodes in the magnum capi worker cluster",
        labelnames=["deployment"],
        namespace="openstack_magnum",
        registry=registry,
    )
    pod_gauge = Gauge(
        "capi_worker_pod_running_count",
        "Number of running pods in a given namespace in the magnum capi worker cluster",
        labelnames=["deployment", "namespace"],
        namespace="openstack_magnum",
        registry=registry,
    )
    error_gauge = Gauge(
        "capi_worker_metric_errors",
        "Number of errors found when checking capi worker metrics",
        labelnames=["deployment"],
        namespace="openstack_magnum",
        registry=registry,
    )
    worker_gauge.labels(deployment).set(ready_nodes_count(kubeclient))

    for ns in kubeclient.list_namespace().items:
        pod_gauge.labels(deployment, ns.metadata.name).set(
            pod_phase_count(kubeclient, ns.metadata.name)
        )

    error_gauge.labels(deployment).set(error_count)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export a few stats about the magnum cluster api (capi) worker cluster"
    )
    parser.add_argument(
        "--outfile",
        type=Path,
        default=Path(
            "/var/lib/prometheus/node.d/openstack_magnum_capi_worker_cluster.prom"
        ),
        help="Output file (e.g., /var/lib/prometheus/node.d/foo.prom)",
    )
    parser.add_argument(
        "--kubeconfig",
        type=Path,
        default=Path("/var/lib/magnum/.kube/config"),
        help="Path to capi worker cluster kubeconfig",
    )
    parser.add_argument(
        "--deployment",
        type=Path,
        required=True,
        help="Openstack deployment (eqiad1 or codfw1dev)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    registry = CollectorRegistry()
    export_capi_worker_metrics(registry, args.deployment, args.kubeconfig)
    write_to_textfile(args.outfile, registry)


if __name__ == "__main__":
    sys.exit(main())
