class k8s::proxy(
    $master_host,
) {
    file { '/usr/local/bin/kube-proxy':
        source => '/data/scratch/k8s/kubernetes/server/bin/kube-proxy',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    base::service_unit { 'kube-proxy':
        systemd => true,
        require => File['/usr/local/bin/kube-proxy'],
    }
}
