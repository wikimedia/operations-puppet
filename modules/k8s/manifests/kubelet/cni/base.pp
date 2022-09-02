# SPDX-License-Identifier: Apache-2.0
# == Class k8s::kubelet::cni::base
#
# Installs base/common configs for the Kubelets cni plugins.

class k8s::kubelet::cni::base {
    file { ['/etc/cni', '/etc/cni/net.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
