class toolforge::k8s::kubeadm(
) {
    require ::toolforge::k8s::kubeadmrepo

    $packages = [
        'kubeadm',
        'kubectl',
        'kubernetes-cni',
        'docker-ce',
        'docker-ce-cli',
        'containerd.io',
        'cri-tools',
    ]

    package { $packages:
        ensure => 'present',
    }


    file { '/etc/systemd/system/docker.service.d':
        ensure => 'directory',
    }

    file { '/etc/docker/daemon.json':
        source  => 'puppet:///modules/toolforge/docker-config.json',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['docker'],
        require => Package['docker-ce'],
    }

    file { '/etc/kubernetes/':
        ensure => 'directory',
    }
}
