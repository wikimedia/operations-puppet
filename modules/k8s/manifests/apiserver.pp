class k8s::apiserver(
    $etcd_servers,
    $master_host,
) {
    require_package('kube-apiserver')

    include k8s::users

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0700',
    }

    file { '/etc/kubernetes/tokenauth':
        source => '/srv/kube-tokenauth',
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0400',
        notify => Base::Service_unit['kube-apiserver'],
    }

    file { '/etc/kubernetes/abac':
        source => '/srv/kube-abac',
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0400',
        notify => Base::Service_unit['kube-apiserver'],
    }

    class { '::k8s::ssl':
        provide_private => true,
        user            => 'kubernetes',
        group           => 'kubernetes',
        notify          => Base::Service_unit['kube-apiserver'],
    }

    base::service_unit { 'kube-apiserver':
        systemd => true,
    }
}
