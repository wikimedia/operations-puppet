class k8s::apiserver(
    $etcd_servers,
    $docker_registry,
    $ssl_cert_path=undef,
    $ssl_key_path=undef,
    $kube_api_port = undef,
    $kubelet_port = undef,
    $service_cluster_ip_range = '192.168.0.0/17',
    $admission_controllers = [
        'NamespaceLifecycle',
        'ResourceQuota',
        'LimitRanger',
        'UidEnforcer',
        'RegistryEnforcer',
        'HostAutomounter',
        'HostPathEnforcer',
    ],
    $host_automounts = [],
    $host_paths_allowed = [],
    $host_path_prefixes_allowed = [],
    $authz_mode = 'abac',
    $apiserver_count = undef,
) {
    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'kube',
        group  => 'kube',
        mode   => '0700',
    }

    require_package('kubernetes-master')
    require_package('kubernetes-client')

    $host_automounts_string = join($host_automounts, ',')
    $host_paths_allowed_string = join(concat($host_paths_allowed, $host_automounts), ',')
    $host_path_prefixes_allowed_string = join($host_path_prefixes_allowed, ',')
    $admission_control = join($admission_controllers, ',')

    $users = hiera('k8s_infrastructure_users')
    file { '/etc/kubernetes/infrastructure-users':
        content => template('k8s/infrastructure-users.csv.erb'),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
    }

    file { '/etc/default/kube-apiserver':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('k8s/kube-apiserver.default.erb'),
        notify  => Service['kube-apiserver'],
    }

    service { 'kube-apiserver':
        ensure => running,
    }
}
