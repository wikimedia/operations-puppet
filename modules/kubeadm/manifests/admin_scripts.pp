# SPDX-License-Identifier: Apache-2.0
class kubeadm::admin_scripts (
) {
    file { '/root/.kube':
        ensure => directory,
    }

    file { '/root/.kube/config':
        ensure => link,
        target => '/etc/kubernetes/admin.conf',
    }

    file { '/usr/local/sbin/wmcs-k8s-get-cert':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/kubeadm/admin_scripts/wmcs-k8s-get-cert.sh',
    }

    file { '/usr/local/sbin/wmcs-k8s-secret-for-cert':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/kubeadm/admin_scripts/wmcs-k8s-secret-for-cert.sh',
    }

    file { '/usr/local/sbin/wmcs-k8s-enable-cluster-monitor':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/kubeadm/admin_scripts/wmcs-k8s-enable-cluster-monitor.sh',
    }
}
