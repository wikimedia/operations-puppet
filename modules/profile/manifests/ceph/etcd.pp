class profile::ceph::etcd(
    Array[Stdlib::Fqdn] $etcd_hosts     = lookup('profile::ceph::mon_hosts'),
    Optional[Boolean]   $etcd_bootstrap = lookup('profile::ceph::etcd::bootstrap', {'default_value' => false}),
) {
    # ETCD initial state
    $cluster_state = $etcd_bootstrap ? {
        true => 'new',
        default => 'existing',
    }

    # ETCD_INITIAL_CLUSTER peer connection string
    $etcd_peers = join($etcd_hosts.map |$peer| { "${peer}=https://${peer}:2380" }, ',')

    # ETCD SSL certificates provided by base::export_puppet_certs
    $client_cert = '/etc/etcd/ssl/cert.pem'
    $client_key  = '/etc/etcd/ssl/server.key'
    $trusted_ca  = '/usr/local/share/ca-certificates/Puppet_Internal_CA.crt'

    # Create the base directory for the SSL certificates
    file { ['/etc/etcd/']:
        ensure => directory,
    }

    base::expose_puppet_certs { '/etc/etcd':
        ensure          => present,
        provide_private => true,
        user            => 'etcd',
        group           => 'etcd',
        before          => Service['etcd'],
        notify          => Service['etcd'],
    }

    class { 'etcd::v3':
        member_name      => $::fqdn,
        cluster_state    => $cluster_state,
        peers_list       => $etcd_peers,
        use_client_certs => true,
        client_cert      => $client_cert,
        client_key       => $client_key,
        peer_cert        => $client_cert,
        peer_key         => $client_key,
        trusted_ca       => $trusted_ca,
    }

    $etcd_ferm_clients = join($etcd_hosts, ' ')
    ferm::service { 'etcd_clients':
        proto  => 'tcp',
        port   => 2379,
        srange => "@resolve((${etcd_ferm_clients}))",
    }
    ferm::service { 'etcd_peers':
        proto  => 'tcp',
        port   => 2380,
        srange => "@resolve((${etcd_ferm_clients}))",
    }
}
