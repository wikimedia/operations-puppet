#!/bin/bash
# SPDX-License-Identifier: MIT
# This file is managed by Puppet (modules/kubeadm/files/helm-sudo.sh).
#

exec kubectl --kube-as-user=${USER} --kube-as-group=system:masters "$@"
