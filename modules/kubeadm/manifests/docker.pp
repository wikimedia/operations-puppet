# SPDX-License-Identifier: Apache-2.0
class kubeadm::docker (
) {
    require ::kubeadm::repo

    $packages = [
        'docker-ce',
        'docker-ce-cli',
    ]

    package { $packages:
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }

    # I think this is unused? It is called for specifically in Kubernetes docs.  Don't know why.
    file { '/etc/systemd/system/docker.service.d':
        ensure => 'directory',
    }

    service { 'docker':
        ensure => 'running'
    }

    file { '/etc/docker/daemon.json':
        source  => 'puppet:///modules/toolforge/docker-config.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['docker'],
        require => Package['docker-ce'],
    }
}
