# SPDX-License-Identifier: Apache-2.0
class kubeadm::kubectl (
) {
    require ::kubeadm::repo

    package  { 'kubectl':
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }

    file { '/usr/local/bin/kubectl-sudo':
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/kubeadm/kubectl-sudo.sh',
    }
}
