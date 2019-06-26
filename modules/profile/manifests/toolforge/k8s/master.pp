class profile::toolforge::k8s::master(
    Stdlib::Fqdn        $master_fqdn  = lookup('profile::toolforge::k8s::master::master_fqdn', {default_value => 'localhost'}),
    Array[Stdlib::Fqdn] $etcd_servers = lookup('profile::toolforge::k8s::etcd_hosts',          {default_value => ['localhost']}),
) {
    requires_os('debian >= stretch')

    # the certificate trick
    $k8s_cert_pub     = '/etc/kubernetes/ssl/cert.pem'
    $k8s_cert_priv    = '/etc/kubernetes/ssl/cert.priv'
    $k8s_cert_ca      = '/etc/kubernetes/ssl/ca.pem'
    $puppet_cert_pub  = "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    $puppet_cert_priv = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    $puppet_cert_ca   = '/var/lib/puppet/ssl/certs/ca.pem'

    file { '/etc/kubernetes/ssl/':
        ensure => directory,
    }

    file { $k8s_cert_pub:
        ensure => present,
        source => "file://${puppet_cert_pub}",
        owner  => 'kube',
        group  => 'kube',
    }

    file { $k8s_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        owner     => 'kube',
        group     => 'kube',
        mode      => '0640',
        show_diff => false,
    }

    file { $k8s_cert_ca:
        ensure => present,
        source => "file://${puppet_cert_ca}",
        owner  => 'kube',
        group  => 'kube',
    }

    # we need a string like:
    # https://node1.example.com:2379,https://node2.example.com:2379
    $scheme = 'https://'
    $port   = '2379'
    $etcd_servers_array = map($etcd_servers) |$element| {
        $value = "${scheme}${element}:${port}"
    }
    $etcd_servers_string = join($etcd_servers_array, ',')
    class { '::k8s::apiserver':
        etcd_servers             => $etcd_servers_string,
        ssl_cert_path            => $k8s_cert_pub,
        ssl_key_path             => $k8s_cert_priv,
        authz_mode               => 'RBAC',
        storage_backend          => 'etcd3',
        service_cluster_ip_range => '192.168.0.0/17',
        service_node_port_range  => '1-65535',
        apiserver_count          => 1,
    }

    class { '::k8s::scheduler': }
    class { '::k8s::controller':
        service_account_private_key_file => $k8s_cert_priv,
    }

    # TODO: maintain_kubeuser is sensitive of the rbac vs abac stuff
    class { '::toolforge::maintain_kubeusers':
        k8s_master => $master_fqdn,
    }

    # TODO: use proper ranges
    ferm::service { 'apiserver-https':
        proto  => 'tcp',
        port   => '6443',
        srange => '172.16.0.0/16',
    }
}
