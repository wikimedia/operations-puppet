#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""
Reads --node-labels out of /etc/default/kubelet's DAEMON_ARGS, then
PATCHes the corresponding Kubernetes Node object so its labels match
exactly what's in that file - other labels on the Node are left alone.
Label keys that this script previously set but that have since been
removed from the daemon file are also removed from the Node, tracked
via a state file (see --state-file).

Authenticates using the kubelet's own kubeconfig (client cert/key +
CA), i.e. the node's own credentials and RBAC permissions.

Writes a Prometheus textfile-collector metrics file for node_exporter
with the outcome of the last run (see --metrics-dir).

Quiet by default - only warnings and errors are printed. Use -v/--verbose
or --dry-run to also see the details of what was found and changed.

Usage:
    sync_kubelet_node_labels.py [--dry-run] [-v] [--daemon-file PATH] [--kubeconfig PATH]
                         [--state-file PATH] [--metrics-dir PATH]
"""

import argparse
import logging
import sys
import time
from pathlib import Path

import requests
import yaml
from prometheus_client import CollectorRegistry, Gauge, write_to_textfile

DEFAULT_DAEMON_FILE = Path("/etc/default/kubelet")

log = logging.getLogger("sync_kubelet_node_labels")


class NodeNameMismatch(Exception):
    """Raised when the state file belongs to a different node than the one running now."""


def parse_labels_file(labels_file: Path) -> tuple[str, dict[str, str | None]]:
    """Parse the node labels YAML file and return a tuple of (node, labels)."""
    with labels_file.open() as f:
        data = yaml.safe_load(f) or {}

    node_name = data.get("node", "")
    labels = {}
    # Labels are stored as a list of "key=value" strings
    for pair in data.get("labels", []):
        label, _, value = pair.partition("=")
        labels[label] = value

    return node_name, labels


def load_managed_labels(state_file: Path, node_name: str) -> set:
    """Return the set of label keys this script previously set on this node,
    as recorded after the last successful patch. Returns an empty set if
    there's no state file yet or it's unreadable. Raises NodeNameMismatch
    if the state file was written for a different node."""
    if not state_file.exists():
        return set()

    try:
        with state_file.open() as f:
            data = yaml.safe_load(f) or {}
    except (yaml.YAMLError, OSError) as exc:
        log.warning(
            "could not read state file %s (%s), treating as empty.", state_file, exc
        )
        return set()

    recorded_node = data.get("node")
    if recorded_node is not None and recorded_node != node_name:
        raise NodeNameMismatch(
            f"state file {state_file} was written for node {recorded_node!r}, "
            f"but this node is {node_name!r}"
        )

    return set(data.get("labels", []))


def save_managed_labels(state_file: Path, node_name: str, keys) -> None:
    state_file.parent.mkdir(parents=True, exist_ok=True)
    state_file.write_text(
        yaml.safe_dump({"node": node_name, "labels": sorted(keys)}, sort_keys=False)
    )


def load_kubeconfig(kubeconfig_path: Path) -> tuple[str, tuple]:
    """Parse the kubeconfig and return (api_server_url, (cert_path, key_path))."""
    with kubeconfig_path.open() as f:
        config = yaml.safe_load(f)

    current_context_name = config["current-context"]
    context = next(
        c["context"] for c in config["contexts"] if c["name"] == current_context_name
    )

    cluster = next(
        c["cluster"] for c in config["clusters"] if c["name"] == context["cluster"]
    )
    user = next(u["user"] for u in config["users"] if u["name"] == context["user"])

    apiserver = cluster["server"]

    cert_path = user.get("client-certificate")
    key_path = user.get("client-key")

    if not (cert_path and key_path):
        raise ValueError(
            "kubeconfig has no client-certificate/client-key file paths configured"
        )

    return apiserver, (cert_path, key_path)


def check_patch_permission(api_server_url: str, cert: tuple, node_name: str) -> bool:
    """Use a SelfSubjectAccessReview to check whether kubelet credentials
    are allowed to patch this Node object."""
    review = {
        "apiVersion": "authorization.k8s.io/v1",
        "kind": "SelfSubjectAccessReview",
        "spec": {
            "resourceAttributes": {
                "group": "",
                "resource": "nodes",
                "name": node_name,
                "verb": "patch",
            }
        },
    }
    url = f"{api_server_url}/apis/authorization.k8s.io/v1/selfsubjectaccessreviews"
    response = requests.post(url, json=review, cert=cert)
    response.raise_for_status()
    return response.json().get("status", {}).get("allowed", False)


def get_node_labels(api_server_url: str, cert: tuple, node_name: str) -> dict:
    url = f"{api_server_url}/api/v1/nodes/{node_name}"
    response = requests.get(url, cert=cert)
    response.raise_for_status()
    return response.json().get("metadata", {}).get("labels", {}) or {}


def patch_node_labels(
    api_server_url: str, cert: tuple, node_name: str, labels: dict
) -> None:
    url = f"{api_server_url}/api/v1/nodes/{node_name}"
    patch_body = {"metadata": {"labels": labels}}
    headers = {"Content-Type": "application/merge-patch+json"}
    response = requests.patch(url, json=patch_body, headers=headers, cert=cert)
    response.raise_for_status()


def write_metrics(metrics_dir: Path, success: bool) -> None:
    """Write a node_exporter textfile-collector .prom file with the outcome
    of this run. Raises OSError on failure."""
    registry = CollectorRegistry()
    Gauge(
        "node_label_sync_success",
        "Whether the last node-label sync run succeeded (1) or failed (0)",
        registry=registry,
    ).set(1 if success else 0)
    Gauge(
        "node_label_sync_last_run_timestamp_seconds",
        "Unix timestamp of the last node-label sync run",
        registry=registry,
    ).set(time.time())

    out_dir = Path(metrics_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    write_to_textfile(str(out_dir / "sync_kubelet_node_labels.prom"), registry)


def try_write_metrics(metrics_dir: Path, success: bool) -> bool:
    """write_metrics, but turns a failure into a logged error and False
    instead of an exception, so the caller can fold it into the exit code."""
    try:
        write_metrics(metrics_dir, success)
        return True
    except OSError as exc:
        log.error("could not write metrics to %s: %s", metrics_dir, exc)
        return False


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--labels-file",
        default=Path("/etc/kubernetes/node-labels.yaml"),
        type=Path,
        help="Path to the file containing node labels managed by puppet",
    )
    parser.add_argument("--kubeconfig", default=Path("/etc/kubernetes/kubelet.conf"), type=Path)
    parser.add_argument(
        "--state-file",
        default=Path("/var/lib/kubelet/node-labels-state.yaml"),
        type=Path,
        help=(
            "Where to record label keys this script manages, so it can remove "
            "ones no longer in the labels file"
        ),
    )
    parser.add_argument(
        "--metrics-dir",
        default=Path("/var/lib/prometheus/node-exporter"),
        type=Path,
        help="node_exporter textfile-collector directory to write run metrics into",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "Show what would change and check RBAC permission, without patching "
            "(implies --verbose)"
        ),
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print what was found and changed, not just warnings/errors",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO if (args.verbose or args.dry_run) else logging.WARNING,
        format="%(levelname)s: %(message)s",
    )

    try:
        node_name, desired_labels = parse_labels_file(args.labels_file)
    except (OSError, ValueError) as exc:
        log.exception("%s", exc)
        try_write_metrics(args.metrics_dir, success=False)
        return 1

    if not desired_labels:
        log.info("No labels found in %s, nothing to do.", args.labels_file)
        metrics_ok = try_write_metrics(args.metrics_dir, success=True)
        return 0 if metrics_ok else 1

    try:
        managed_labels = load_managed_labels(args.state_file, node_name)
    except NodeNameMismatch as exc:
        log.exception("%s", exc)
        try_write_metrics(args.metrics_dir, success=False)
        return 1

    labels_to_remove = managed_labels - desired_labels.keys()

    log.info("Node: %s", node_name)
    log.info("Desired labels from %s:", args.labels_file)
    for key, value in sorted(desired_labels.items()):
        log.info("  %s=%s", key, value)
    if labels_to_remove:
        log.info("Previously managed labels no longer present (will be removed):")
        for key in sorted(labels_to_remove):
            log.info("  %s", key)

    patch_labels = desired_labels.copy()
    for key in labels_to_remove:
        patch_labels[key] = None

    try:
        server, cert = load_kubeconfig(args.kubeconfig)
    except (OSError, ValueError, KeyError, StopIteration) as exc:
        log.exception("%s", exc)
        try_write_metrics(args.metrics_dir, success=False)
        return 1

    if args.dry_run:
        log.info("API server: %s", server)

        try:
            allowed = check_patch_permission(server, cert, node_name)
        except requests.HTTPError as exc:
            log.exception("permission check failed: %s", exc)
            return 1

        if allowed:
            log.info("Permission check: OK - these credentials can patch this node.")
        else:
            log.info(
                "Permission check: DENIED - these credentials cannot patch this node."
            )

        try:
            current_labels = get_node_labels(server, cert, node_name)
        except requests.HTTPError as exc:
            log.exception("could not fetch current node labels: %s", exc)
            return 1

        log.info("Changes that would be applied:")
        changed = False
        for key, value in sorted(desired_labels.items()):
            current_value = current_labels.get(key)
            if current_value != value:
                changed = True
                log.info("  %s: %r -> %r", key, current_value, value)
        for key in sorted(labels_to_remove):
            changed = True
            log.info("  %s: %r -> (removed)", key, current_labels.get(key))
        if not changed:
            log.info("  (none, labels already match)")

        return 0 if allowed else 1

    try:
        patch_node_labels(server, cert, node_name, patch_labels)
    except requests.HTTPError as exc:
        log.exception("patch failed: %s", exc)
        try_write_metrics(args.metrics_dir, success=False)
        return 1

    save_managed_labels(args.state_file, node_name, desired_labels.keys())
    log.info(
        "Patched %d label(s), removed %d label(s) on node %s.",
        len(desired_labels),
        len(labels_to_remove),
        node_name,
    )

    metrics_ok = try_write_metrics(args.metrics_dir, success=True)
    return 0 if metrics_ok else 1


if __name__ == "__main__":
    sys.exit(main())
