class k8s::kubelet(
    $master_host,
) {
    file { '/usr/local/bin/kubelet':
        source => '/data/scratch/k8s/kubernetes/server/bin/kubelet',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/kuebernetes/manifests':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $master_ip = ipresolve($master_host)
    base::service_unit { 'kubelet':
        systemd => true,
        require => File['/usr/locall/bin/kubelet'],
    }
}
