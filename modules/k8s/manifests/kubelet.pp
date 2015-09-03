class k8s::kubelet(
    $master_host,
    $cluster_dns_ip = '192.168.0.100',
) {
    file { '/usr/local/bin/kubelet':
        source => '/data/scratch/k8s/kubernetes/server/bin/kubelet',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { [
        '/etc/kubernetes/',
        '/etc/kubernetes/manifests',
    ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])
    base::service_unit { 'kubelet':
        systemd => true,
        require => File['/usr/local/bin/kubelet'],
    }
}
