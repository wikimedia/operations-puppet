class k8s::apiserver(
    $etcd_servers,
    $master_host,
    $docker_registry,
    $host_automounts = [],
) {
    include k8s::users

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0700',
    }

    $host_automounts_string = join($host_automounts, ',')

    $users = hiera('k8s_users')
    file { '/etc/kubernetes/tokenauth':
        content => template('k8s/tokenauth.csv.erb'),
        owner   => 'kubernetes',
        group   => 'kubernetes',
        mode    => '0400',
        notify  => Base::Service_unit['kube-apiserver'],
    }

    # List of resources that namespaced users can access
    $namespace_allowed_resources = [
        'pods',
        'replicationcontrollers',
        'services',
        'secrets',
    ]

    file { '/etc/kubernetes/abac':
        content => template('k8s/abac.json.erb'),
        owner   => 'kubernetes',
        group   => 'kubernetes',
        mode    => '0400',
        notify  => Base::Service_unit['kube-apiserver'],
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
