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

    file { '/etc/kube':
        ensure => directory,
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0700',
    }

    file { '/etc/kube/tokenauth':
        source => '/srv/kube-tokenauth',
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0400',
    }

    file { '/etc/kube/abac':
        source => '/srv/kube-abac',
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0400',
    }

    file { '/var/run/kubernetes':
        ensure => directory,
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0770',
    }

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])
    base::service_unit { 'kube-apiserver':
        systemd => true,
    }
}
