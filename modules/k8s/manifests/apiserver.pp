class k8s::apiserver(
    $etcd_servers,
) {
    file { '/usr/local/bin/kube-apiserver':
        source => '/data/scratch/k8s/kubernetes/server/bin/kube-apiserver',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])
    base::service_unit { 'kube-apiserver':
        systemd => true,
        require => File['/usr/local/bin/kube-apiserver'],
    }
}
