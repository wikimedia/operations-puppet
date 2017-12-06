class k8s::apiserver(
    $etcd_servers,
    $ssl_cert_path=undef,
    $ssl_key_path=undef,
    $kube_api_port = undef,
    $kubelet_port = undef,
    $service_cluster_ip_range = '192.168.0.0/17',
    $admission_controllers = {
        'NamespaceLifecycle' => '',
        'LimitRanger' => '',
        'ServiceAccount' => '',
        'DefaultStorageClass' => '',
        'ResourceQuota' => '',
    },
    $authz_mode = 'abac',
    $storage_backend = 'etcd2',
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

    $admission_control = join(keys($admission_controllers), ',')
    $admission_control_params = lstrip(join(values($admission_controllers), ' '))

    $users = hiera('k8s_infrastructure_users')
    file { '/etc/kubernetes/infrastructure-users':
        content => template('k8s/infrastructure-users.csv.erb'),
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        notify  => Service['kube-apiserver'],
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
        enable => true,
    }
}
