class k8s::scheduler(
    $master_host,
) {
    file { '/usr/local/bin/kube-scheduler':
        source => '/data/scratch/k8s/kubernetes/server/bin/kube-scheduler',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    base::service_unit { 'kube-scheduler':
        systemd => true,
        require => File['/usr/local/bin/kube-scheduler'],
    }
}
