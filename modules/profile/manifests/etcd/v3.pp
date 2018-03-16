# == Class profile::etcd::v3
#
# Installs an etcd version 3 server, as part of a cluster
#
# === Parameters
#
# [*cluster_name*]
#   name of the cluster. This parameter is needed.
#
# [*cluster_bootstrap*]
#   Boolean. set to true if we're just bootstrapping the cluster.
#
# [*discovery*]
#   Can be either 'dns:domain_name', which means that the cluster composition will be
#   discovered with _etcd-server._tcp.$cluster_name, or a comma-separated list
#   of peers in the form name=peer_url
#
# [*use_client_certs*]
#   Boolean. Wether to set up TLS client cert based auth
#
# [*allow_from*]
#   Networks authorized to connect to the server.
#
# [*do_backup*]
#   Boolean. Whether to back up the data on etcd or not
#
# [*max_latency*]
#   Maximum RTT between current cluster nodes
class profile::etcd::v3(
    # Configuration
    String $cluster_name = hiera('profile::etcd::v3::cluster_name'),
    Boolean $cluster_bootstrap = hiera('profile::etcd::v3::cluster_bootstrap', false),
    String $discovery = hiera('profile::etcd::v3::discovery'),
    Boolean $use_client_certs = hiera('profile::etcd::v3::use_client_certs'),
    String $allow_from = hiera('profile::etcd::v3::allow_from'),
    Integer $max_latency = hiera('profile::etcd::v3::max_latency'),
) {
    # Parameters mangling
    $cluster_state = $cluster_bootstrap ? {
        true    => 'new',
        default => 'existing',
    }

    if $discovery =~ /dns:(.*)/ {
        $peers_list = undef
        $srv_dns = $1
    } else {
        $peers_list = $discovery
        $srv_dns = undef
    }

    # TLS certs *for etcd use*, they're generated with cergen.
    # Tlsproxy will use other certificates.
    sslcert::certificate { $::fqdn:
        skip_private => false,
        before       => Service['etcd'],
    }

    # Service
    # Until we're able to move to v3, we're going to serve
    # the v2 store on port 4001, proxied by nginx that does all the
    # auth stuff for etcd.
    class { '::etcd::v3':
        cluster_name     => $cluster_name,
        cluster_state    => $cluster_state,
        srv_dns          => $srv_dns,
        peers_list       => $peers_list,
        use_client_certs => $use_client_certs,
        max_latency_ms   => $max_latency,
        adv_client_port  => 4001,
        trusted_ca       => '/etc/ssl/certs/Puppet_Internal_CA.pem',
        client_cert      => "/etc/ssl/localcerts/${::fqdn}.crt",
        client_key       => "/etc/ssl/private/${::fqdn}.crt",
        peer_cert        => "/etc/ssl/localcerts/${::fqdn}.crt",
        peer_key         => "/etc/ssl/private/${::fqdn}.crt",
    }

    # Monitoring
    class { '::etcd::v3::monitoring': }

    # Firewall
    ferm::service { 'etcd_clients':
        proto  => 'tcp',
        port   => 2379,
        srange => $allow_from,
    }

    ferm::service { 'etcd_peers':
        proto  => 'tcp',
        port   => 23,
        srange => '$DOMAIN_NETWORKS',
    }
}
