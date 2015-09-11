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
        notify => Base::Service_unit['kube-apiserver'],
    }

    file { '/etc/kubernetes/abac':
        source => '/srv/kube-abac',
        owner  => 'kube-apiserver',
        group  => 'kube-apiserver',
        mode   => '0400',
        notify => Base::Service_unit['kube-apiserver'],
    }

    class { '::k8s::ssl':
        provide_private => true,
        notify => Base::Service_unit['kube-apiserver'],
    }

    base::service_unit { 'kube-apiserver':
        systemd => true,
    }
}
