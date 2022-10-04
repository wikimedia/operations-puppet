# SPDX-License-Identifier: Apache-2.0
# == Class k8s::kubelet::cni
#
# Installs and configures a CNI config file, that can be composed by multiple
# plugins. The related Kubeconfigs for users need to be deployed separately.
#
define k8s::kubelet::cni (
    Hash $config,
    Integer $priority,
) {
    require k8s::kubelet::cni::base

    file { "/etc/cni/net.d/${priority}-${title}.conflist":
        content => template('k8s/kubelet/cni.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }
}
