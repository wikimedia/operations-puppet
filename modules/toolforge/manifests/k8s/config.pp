# SPDX-License-Identifier: Apache-2.0
# toolforge specific config for our kubeadm-based k8s deployment
class toolforge::k8s::config (
) {
    # make sure you declare ::kubeadm::core somewhere in the calling profile
    # because /etc/kubernetes

    file { '/etc/kubernetes/toolforge-tool-roles.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/toolforge-tool-roles.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
