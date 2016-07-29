#!/bin/bash
# Simple script that only downloads kubelet/kube-proxy
# Useful for first run scenarios
set -o errexit
set -o nounset

# TODO: Add error checking (baaaaassshhhhh)
URL_PREFIX="${1:?URL_PREFIX is required}"
VERSION="${2:?VERSION is required}"

# Download the new things!
wget -O /usr/local/bin/kubelet $URL_PREFIX/$VERSION/kubelet
wget -O /usr/local/bin/kube-proxy $URL_PREFIX/$VERSION/kube-proxy

# Make them executable!
chmod u+x /usr/local/bin/kubelet
chmod u+x /usr/local/bin/kube-proxy