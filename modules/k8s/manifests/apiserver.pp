class k8s::apiserver(
    $etcd_servers,
    $master_host,
) {
    require_package('kube-apiserver')

    group { 'kube-apiserver':
        ensure => present,
        system => true,
    }

    user { 'kube-apiserver':
        ensure     => present,
        shell      => '/bin/false',
        system     => true,
        managehome => false,
    }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0700',
    }

    file { '/etc/kubernetes/tokenauth':
        source => '/srv/kube-tokenauth',
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0400',
    }

    file { '/etc/kubernetes/abac':
        source => '/srv/kube-abac',
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0400',
    }

    include k8s::apiserver_ssl

    base::service_unit { 'kube-apiserver':
        systemd => true,
    }
}
