class k8s::apiserver(
    $etcd_servers,
    $master_host,
    $docker_registry,
    $ssl_certificate_name,
    $host_automounts = [],
    $host_paths_allowed = [],
    $host_path_prefixes_allowed = [],
) {
    include k8s::users

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'kubernetes',
        group  => 'kubernetes',
        mode   => '0700',
    }

    $host_automounts_string = join($host_automounts, ',')
    $host_paths_allowed_string = join(concat($host_paths_allowed, $host_automounts), ',')
    $host_path_prefixes_allowed_string = join($host_path_prefixes_allowed, ',')

    $users = hiera('k8s_infrastructure_users')
    file { '/etc/kubernetes/infrastructure-users':
        content => template('k8s/infrastructure-users.csv.erb'),
        owner   => 'kubernetes',
        group   => 'kubernetes',
        mode    => '0400',
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
