# SPDX-License-Identifier: Apache-2.0
class kubeadm::calico_yaml (
    String              $pod_subnet,
    String              $calico_version = 'v3.21.0',
    Boolean             $typha_enabled = false,
    Integer             $typha_replicas = 3,
) {
    # because /etc/kubernetes
    require ::kubeadm::core

    file { '/etc/kubernetes/calico.yaml':
        ensure  => present,
        content => template('kubeadm/calico.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/calicoctl.yaml':
        ensure  => present,
        content => template('kubeadm/calicoctl.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/root/.bash_aliases':
        ensure => present,
        source => 'puppet:///modules/kubeadm/root-bash-aliases',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
