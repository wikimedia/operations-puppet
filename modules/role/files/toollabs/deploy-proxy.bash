#!/bin/bash
# This script does the following:
#
# 1. Stop the K8S Proxy
# 2. Download new versions of Proxy from a central location
# 3. Start the K8S Proxy

set -e

# TODO: Add error checking (baaaaassshhhhh)
URL_PREFIX="$1"
VERSION="$2"

# Stop all the running services!
service kubeproxy stop

# Download the new things!
wget -O /usr/local/bin/kube-proxy $URL_PREFIX/$VERSION/kube-proxy

# Make it executable!
chmod u+x /usr/local/bin/kube-proxy

# Start services again, and hope!
service kube-proxy start
