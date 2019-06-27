class k8s::apiserver(
    String $etcd_servers,
    Optional[Stdlib::Unixpath] $ssl_cert_path=undef,
    Optional[Stdlib::Unixpath] $ssl_key_path=undef,
    Optional[Stdlib::Port] $kube_api_port = undef,
    Optional[Stdlib::Port] $kubelet_port = undef,
    Stdlib::IP::Address $service_cluster_ip_range = '192.168.0.0/17',
    Optional[String] $service_node_port_range = undef,
    Hash[String, String] $admission_controllers = {
        'NamespaceLifecycle' => '',
        'LimitRanger' => '',
        'ServiceAccount' => '',
        'DefaultStorageClass' => '',
        'ResourceQuota' => '',
    },
    String $authz_mode = 'abac',
    String $storage_backend = 'etcd2',
    Optional[Integer] $apiserver_count = undef,
    Optional[String] $runtime_config = undef,
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
