#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
DRY_RUN=${DRY_RUN:-false}

function reload_certs_in_cluster_namespace() {
    export KUBECONFIG="/etc/kubernetes/admin-${CLUSTER}.config"
    # Get the oldest pod creation date and the newest certificate creation date
    # We only count pods that are in a running state.
    POD_CREATION_DATE=$(kubectl -n "$NAMESPACE" get pods -l "${LABEL_NAME}=${LABEL_VALUE}" -o json | jq -r '.items | map(select(.status.phase == "Running")) | [.[].metadata.creationTimestamp] | min')
    POD_CREATION_TIME=$(date --date="$POD_CREATION_DATE" +"%s")
    CERT_NOT_BEFORE_DATE=$(kubectl -n "$NAMESPACE" get certificates -l "${LABEL_NAME}=${LABEL_VALUE}" -o json | jq -r '.items | [.[].status.notBefore] | max')
    CERT_NOT_BEFORE_TIME=$(date --date="$CERT_NOT_BEFORE_DATE" +"%s")

    if [[ $CERT_NOT_BEFORE_TIME -gt $POD_CREATION_TIME ]]; then
        echo "Reloading certificates for namespace $NAMESPACE in cluster $CLUSTER"
        if [[ "$DRY_RUN" != "true" ]]; then
            pushd "/srv/deployment-charts/helmfile.d/services/${NAMESPACE}"

            if ! helmfile -e "$CLUSTER" diff --detailed-exitcode > /dev/null 2>&1; then
                echo "Helmfile diff found outstanding diffs (or failed) for cluster $CLUSTER and namespace $NAMESPACE"
                exit 1
            fi

            helmfile -e "$CLUSTER" --state-values-set roll_restart=1 sync
            popd
        fi
    else
        echo "No need to reload certificates for namespace $NAMESPACE in cluster $CLUSTER"
    fi
}

CONFIG_FILE="$1"

# Expected JSON config format:
# {
#   "services": {
#     "<namespace1>": [
#       {"cluster": "<cluster1>", "label_name": "<label1>", "label_value": "<value1>"},
#       {"cluster": "<cluster2>", "label_name": "<label2>", "label_value": "<value2>"}
#     ],
#     "<namespace2>": [
#       {"cluster": "<cluster1>", "label_name": "<label1>", "label_value": "<value1>"}
#     ]
#   }
# }
#
# The label_name/label_value pair is used to select the pods and the certificates
# to check in the namespace (e.g. "release": "main").

# Validate the config upfront: errors in the jq process substitution feeding the loop
# below would be silently ignored by set -e.
if ! jq -e '.services | type == "object" and all(.[]; type == "array" and all(.[];
        (.cluster | type == "string" and length > 0)
        and (.label_name | type == "string" and length > 0)
        and (.label_value | type == "string" and length > 0)))' \
        "$CONFIG_FILE" > /dev/null; then
    echo "Invalid configuration file $CONFIG_FILE" >&2
    exit 1
fi

SERVICES=$(jq -r '.services | keys[]' "$CONFIG_FILE")

# HELM_HOME is the same for all users
export HELM_HOME="/etc/helm"
# Helm3 variables (we can share the same config home as filenames differ)
export HELM_CONFIG_HOME="/etc/helm"
# This contains helm plugins
export HELM_DATA_HOME="/usr/share/helm"
# Temporary cache dir for helm
export HELM_CACHE_HOME=/tmp/helm-cache-kube-reload-certs
# Needed to avoid spurious errors with helm and .cache dirs not initialized.
helm repo update

for NAMESPACE in $SERVICES; do
    while IFS=$'\t' read -r CLUSTER LABEL_NAME LABEL_VALUE; do
        reload_certs_in_cluster_namespace
    done < <(jq -r --arg ns "$NAMESPACE" '.services[$ns][] | [.cluster, .label_name, .label_value] | @tsv' "$CONFIG_FILE")
done