#!/bin/bash
# This script does the following:
#
# 1. Stop the K8S master components (API Server, Controller Manager & Scheduler)
# 2. Download new versions of these components from a central location
# 3. Start the K8S master components

set -e

# TODO: Add error checking (baaaaassshhhhh)
URL_PREFIX="$1"
VERSION="$2"

# Stop all the running services!
service kubelet stop 
service kubeproxy stop

# Download the new things!
wget -O /usr/local/bin/kubelet $URL_PREFIX/$VERSION/kubelet
wget -O /usr/local/bin/kube-proxy $URL_PREFIX/$VERSION/kube-proxy

# Start services again, and hope!
service kubelet start
service kube-proxy start
