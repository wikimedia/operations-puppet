#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

if [ "$(id -u)" != "0" ] ; then
    echo "E: need root!" >&2
    exit 1
fi

export KUBECONFIG=/var/lib/magnum/.kube/config
kubectl "$@"
