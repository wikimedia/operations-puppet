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
service kube-apiserver stop 
service controller-manager stop
service kube-scheduler stop

# Download the new things!
wget -O /usr/local/bin/kube-apiserver $URL_PREFIX/$VERSION/kube-apiserver
wget -O /usr/local/bin/kube-scheduler $URL_PREFIX/$VERSION/kube-scheduler
wget -O /usr/local/bin/kube-controller-manager $URL_PREFIX/$VERSION/kube-controller-manager
wget -O /usr/local/bin/kubectl $URL_PREFIX/$VERSION/kubectl

# Owned by the kubernetes user than root!
chown kubernetes /usr/local/bin/kube-apiserver
chown kubernetes /usr/local/bin/kube-scheduler
chown kubernetes /usr/local/bin/kube-controller-manager

# Make them executable
chmod u+x /usr/local/bin/kube-apiserver /usr/local/bin/kube-scheduler
chmod u+x /usr/local/bin/kube-controller-manager

# Executable by all!
chmod +x /usr/local/bin/kubectl

# Start services again, and hope!
service kube-apiserver start
service controller-manager start
service kube-scheduler start
