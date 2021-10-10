#!/bin/sh
# This file is managed by Puppet (modules/kubeadm/files/helm-config.sh).

# Let's not set full HELM_HOME so that full root isn't needed to run
# Helm (per-user caches and repositories), but still load plugins
# installed from Apt and (as a side effect) block non-roots from
# manually installing plugins.
export HELM_PLUGINS=/etc/helm/plugins
