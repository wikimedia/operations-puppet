# == Class profile::etcd
#
# Installs an etcd server, as part of a cluster
#
# === Parameters
#
# [*cluster_name*]
#   name of the cluster. Required
#
# [*cluster_bootstrap*]
#   Boolean. true if just bootstrapping the cluster. Defaults to false
#
# [*discovery*]
#   Can be either 'dns:domain_name', which means that the cluster composition will be
#   discovered with _etcd-server._tcp.$cluster_name, or a comma-separated list
#   of peers in the form name=peer_url. Required
#
# [*use_client_certs*]
#   Boolean. Whether to set up TLS client cert based auth. Required
#
# [*use_proxy*]
#   Boolean. If true, we want clients to connect to etcd via a proxy.
#   The proxy can be set up with profile::etcd::proxy. Required
#
# [*allow_from*]
#   Networks authorized to connect to the server. Required
#
# [*do_backup*]
#   Boolean. Whether to back up the data on etcd or not. Required
#
# [*client_port*]
#   Integer. The port clients will use. Defaults to 2379
#
# [*peer_port*]
#   Integer. The port peers will use. Defaults to 2380
class profile::etcd(
    # Configuration
    String $cluster_name = lookup('profile::etcd::cluster_name'),
    Boolean $cluster_bootstrap = lookup('profile::etcd::cluster_bootstrap', {default_value => false}),
    String $discovery = lookup('profile::etcd::discovery'),
    Boolean $use_client_certs = lookup('profile::etcd::use_client_certs'),
    Boolean $use_proxy = lookup('profile::etcd::use_proxy'),
    String $allow_from = lookup('profile::etcd::allow_from'),
    Boolean $do_backup = lookup('profile::etcd::do_backup'),
    Stdlib::Port $client_port = lookup('etcd::client_port', {default_value => 2379}),
    Stdlib::Port $peer_port = lookup('etcd::peer_port', {default_value => 2380}),
    Integer $heartbeat_interval = lookup('profile::etcd::heartbeat_interval', {default_value => 100}),
    Integer $election_timeout = lookup('profile::etcd::election_timeout', {default_value => 1000}),
){
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

    $adv_client_port = $client_port
    if $use_proxy {
        $real_client_port = $client_port - 1
    }
    else {
        $real_client_port = $client_port
    }

    # Service
    class { '::etcd':
        host               => $::fqdn,
        cluster_name       => $cluster_name,
        cluster_state      => $cluster_state,
        srv_dns            => $srv_dns,
        peers_list         => $peers_list,
        client_port        => $real_client_port,
        adv_client_port    => $adv_client_port,
        use_ssl            => true,
        use_client_certs   => $use_client_certs,
        election_timeout   => $election_timeout,
        heartbeat_interval => $heartbeat_interval,
    }

    # Monitoring
    class { '::etcd::monitoring': }

    # Firewall
    ferm::service{'etcd_clients':
        proto  => 'tcp',
        port   => $adv_client_port,
        srange => $allow_from,
    }

    ferm::service{'etcd_peers':
        proto  => 'tcp',
        port   => $peer_port,
        srange => '$DOMAIN_NETWORKS',
    }

    # Backup
    if $do_backup {
        # Back up etcd
        class { '::etcd::backup':
            cluster_name => $cluster_name,
        }

        #FIXME: this is like this while we migrate to profiles
        include ::profile::backup::host
        backup::set { 'etcd': }
    }

    # Client config
    class { '::etcd::client::globalconfig':
        host       => $::fqdn,
        port       => 2379,
        srv_domain => $srv_dns,
    }

}
