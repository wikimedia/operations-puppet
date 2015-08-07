class k8s::controller(
    $master_host,
) {
    file { '/usr/local/bin/kube-controller-manager':
        source => '/data/scratch/k8s/kubernetes/server/bin/kube-controller-manager',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])
    base::service_unit { 'controller-manager':
        systemd => true,
        require => File['/usr/local/bin/kube-controller-manager'],
    }
}
