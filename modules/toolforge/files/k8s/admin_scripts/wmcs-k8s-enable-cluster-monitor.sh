#!/bin/bash
# Run this script with your root/cluster admin account as appropriate.

set -Eeuo pipefail

function usage {
        echo -e "Usage (must be cluster-admin or similar):\n"
        echo "wmcs-enable-cluster-monitor.sh <tool-name>"
        echo ""
        echo "Example: wmcs-enable-cluster-monitor.sh observer-tool"
}
if [ $# -eq 0 ] || [ $# -gt 1 ]; then
    usage
    exit 1
fi
ARGL=$(echo $1 | wc -c)
if [ $ARGL -gt 58 ]; then
    echo "Name too long to be a real tool"
    usage
    exit 22
fi

namespace="tool-${1}"
tool=$1

if ! kubectl get ns $namespace; then
    echo "********************"
    echo "Namespace doesn't exist -- the tool name must be incorrect"
    usage
    exit 1
fi


echo "Creating the service account..."

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${tool}-obs
  namespace: $namespace
  labels:
    tool.toolforge.org/name: tool-observer
EOF

echo "Enabling read-only access to the cluster..."

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${tool}-obs
  labels:
    tool.toolforge.org/name: tool-observer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tool-observer
subjects:
  - kind: ServiceAccount
    name: ${tool}-obs
    namespace: $namespace
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${tool}-obs-psp
  namespace: $namespace
  labels:
    tool.toolforge.org/name: tool-observer
subjects:
  - kind: ServiceAccount
    name: ${tool}-obs
    namespace: $namespace
roleRef:
  kind: Role
  name: tool-${tool}-psp
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl get serviceaccounts ${tool}-obs -n $namespace
echo "*********************"
echo "Done!"
