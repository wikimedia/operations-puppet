# == Class profile::etcd
#
# Installs an etcd server, as part of a cluster
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
# [*use_proxy*]
#   Boolean. If true, we want clients to connect to etcd via a proxy.
#   The proxy can be set up with profile::etcd::proxy
#
# [*allow_from*]
#   Networks authorized to connect to the server.
#
# [*do_backup*]
#   Boolean. Whether to back up the data on etcd or not
#
# [*client_port*]
#   Integer. The port clients will use. Defaults to 2379
#
# [*peer_port*]
#   Integer. The port peers will use. Defaults to 2380
class profile::etcd(
    # Configuration
    $cluster_name = hiera('profile::etcd::cluster_name'),
    $cluster_bootstrap = hiera('profile::etcd::cluster_bootstrap', false),
    $discovery = hiera('profile::etcd::discovery'),
    $use_client_certs = hiera('profile::etcd::use_client_certs'),
    $use_proxy = hiera('profile::etcd::use_proxy'),
    $allow_from = hiera('profile::etcd::allow_from'),
    $do_backup = hiera('profile::etcd::do_backup'),
    $client_port = hiera('etcd::client_port', 2379),
    $peer_port = hiera('etcd::peer_port', 2380),
    $heartbeat_interval = hiera('profile::etcd::heartbeat_interval', 100),
    $election_timeout = hiera('profile::etcd::election_timeout', 1000),
){
    # Parameters mangling
    $cluster_state = $cluster_bootstrap ? {
        true    => 'new',
        default => 'existing',
    }

    if $discovery =~ /dns:(.*)/ {
        $peers_list = undef
        $srv_dns = $1
    }
    else {
        $peers_list = $discovery
        $srv_dns = undef
    }

    if $use_proxy {
        $real_client_port = $client_port - 1
        $adv_client_port = $client_port
    }
    else {
        $real_client_port = $client_port
        $adv_client_port = $client_port
    }

    # Service & firewalls
    class { '::etcd':
        host               => $::fqdn,
        cluster_name       => $cluster_name,
        cluster_state      => $cluster_state,
        client_port        => $real_client_port,
        adv_client_port    => $adv_client_port,
        srv_dns            => $srv_dns,
        peers_list         => $peers_list,
        use_ssl            => true,
        use_client_certs   => $use_client_certs,
        election_timeout   => $election_timeout,
        heartbeat_interval => $heartbeat_interval,
    }

    class { '::etcd::monitoring': }

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

    # T162013 - reduce raid resync speeds on clustered etcd noes with software RAID
    # in order to mitigate the risk of losing consensus due to I/O latencies
    if 'md' in $facts['raid'] {
        sysctl::parameters { 'raid_resync_speed':
            ensure => present,
            values => { 'dev.raid.speed_limit_max' => '20000' },
        }
        # Only run on a weekday of our choice, and vary it between servers
        $dow = fqdn_rand(5, 'md_checkarray') + 1
        # Replace the default mdadm script from upstream with our own
        file { '/etc/cron.d/mdadm':
            content => template('profile/etcd/mdadm-cron.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }
    }
}
