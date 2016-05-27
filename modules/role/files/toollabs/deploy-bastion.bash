#!/bin/bash
# This script does the following:
#
# - Stop kube-proxy service
# - Download new versions of kube-proxy & kubectl
# - Installs kube-proxy & kubectl in appropriate place
# - Start kube-proxy
set -e

# TODO: Add error checking (baaaaassshhhhh)
URL_PREFIX="$1"
VERSION="$2"

# Stop the running services!
service kube-proxy stop

# Download the new things!
wget -O /usr/local/bin/kubectl $URL_PREFIX/$VERSION/kubectl
wget -O /usr/local/bin/kube-proxy $URL_PREFIX/$VERSION/kube-proxy

# Owned by root!
chown root /usr/local/bin/kubectl
chown root /usr/local/bin/kube-proxy

# Make them executable root only
chmod u+x /usr/local/bin/kube-proxy

# Executable by all!
chmod +x /usr/local/bin/kubectl

# Start services again, and hope!
service kube-proxy start
