# == Class profile::etcd::v3
#
# Installs an etcd version 3 server, as part of a cluster
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
# [*allow_from*]
#   Networks authorized to connect to the server. Required
#
# [*max_latency*]
#   Maximum RTT between current cluster nodes. Required
#
# [*adv_client_port*]
#   Port to advertise to clients. If you're using an auth/TLS terminator
#   (as we do in v2 for RBAC) you will need to advertise its port to the public
#   rather than port 2379 (where etcd listens). Required
#
# [*do_backup*]
#   Boolean. Whether to back up the data on etcd or not. Defaults to false on
#   first deploy for backwards compatibility.
#
# [*quota_backend_bytes*]
#   Integer. The maximum size of the etcd database. Defaults to 2GB.
#
# [*enable_v2*]
#   Whether to enable the v2 API, which is disabled by default on 3.4 (bookworm)
#   or later. If unset, no value is configured.
#

class profile::etcd::v3(
    # Configuration
    String $cluster_name = lookup('profile::etcd::v3::cluster_name'),
    Boolean $cluster_bootstrap = lookup('profile::etcd::v3::cluster_bootstrap', {'default_value' => false}),
    String $discovery = lookup('profile::etcd::v3::discovery'),
    Boolean $use_client_certs = lookup('profile::etcd::v3::use_client_certs'),
    String $allow_from = lookup('profile::etcd::v3::allow_from'),
    Integer $max_latency = lookup('profile::etcd::v3::max_latency'),
    Stdlib::Port $adv_client_port = lookup('profile::etcd::v3::adv_client_port'),
    Boolean $do_backup = lookup('profile::etcd::v3::do_backup', {'default_value' => false}),
    Optional[Integer] $quota_backend_bytes = lookup('profile::etcd::v3::quota_backend_bytes', {'default_value' => undef}),
    Optional[Boolean] $enable_v2 = lookup('profile::etcd::v3::enable_v2', {'default_value' => undef}),
) {
    # Parameters mangling
    $cluster_state = $cluster_bootstrap ? {
        true    => 'new',
        default => 'existing',
    }

    if $discovery =~ /dns:(.*)/ {
        $peers_list = undef
        $srv_dns = $1
        $certname = "_etcd-server-ssl._tcp.${srv_dns}"
    } else {
        $peers_list = $discovery
        $srv_dns = undef
        $certname = $facts['networking']['fqdn']
    }

    # TLS certs *for etcd use* in peer-to-peer communications,
    # tlsproxy will use other certificates.
    # According to https://github.com/etcd-io/etcd/commit/4e21f87e3d014d606bb3ba2a89731a7d24806611
    # etcd does reload the certificate from disc for every client
    # connection. So there is no need to notify the etcd service
    # on certificate renewals.

    # From etcd 3.3+ (bullseye version+) if we use discovery SRV records,
    # we'll also need to add a SAN with the "domain_name: in "dns:domain_name"
    # See T329556
    if $srv_dns != undef {
        $ssl_hosts = [$facts['networking']['fqdn'], $srv_dns]
    } else {
        $ssl_hosts = [$facts['networking']['fqdn']]
    }
    $ssl_paths = profile::pki::get_cert('etcd', $certname, {
        hosts           => $ssl_hosts,
        owner           => 'etcd',
        outdir          => '/var/lib/etcd/ssl',
        before_services => ['etcd'],
    })

    # Service
    class { '::etcd::v3':
        cluster_name        => $cluster_name,
        cluster_state       => $cluster_state,
        srv_dns             => $srv_dns,
        peers_list          => $peers_list,
        use_client_certs    => $use_client_certs,
        max_latency_ms      => $max_latency,
        adv_client_port     => $adv_client_port,
        trusted_ca          => profile::base::certificates::get_trusted_ca_path(),
        client_cert         => $ssl_paths['chained'],
        client_key          => $ssl_paths['key'],
        peer_cert           => $ssl_paths['chained'],
        peer_key            => $ssl_paths['key'],
        quota_backend_bytes => $quota_backend_bytes,
        enable_v2           => $enable_v2,
    }

    # Monitoring
    class { '::etcd::v3::monitoring':
        endpoint => "https://${facts['networking']['fqdn']}:2379"
    }

    # Firewall
    if $allow_from != 'localhost' {
        ferm::service { 'etcd_clients':
            proto  => 'tcp',
            port   => $adv_client_port,
            srange => $allow_from,
        }
    }

    firewall::service { 'etcd_peers':
        proto    => 'tcp',
        port     => 2380,
        src_sets => ['DOMAIN_NETWORKS'],
    }

    # Allow all etcd cluster nodes to connect to each other
    # via client port.
    if $peers_list != undef {
        # If peers are defined in hiera, extract hostnames. Each peer is name=url.
        $peers = split($peers_list, ',').map |$peer| {
            regsubst($peer, '^[^=]+=https?://([^:]+)(:[0-9]+)?', '\1')
        }
    } else {
        # If peers are defined via DNS, resolve the SRV record from $certname
        $peers = dnsquery::srv($certname).map |$srv| { $srv['target'] }
    }
    firewall::service { 'etcd_peers_client_port':
        proto  => 'tcp',
        port   => $adv_client_port,
        srange => sort($peers),
    }

    # Backup
    if $do_backup {
        # Back up etcd
        class { '::etcd::backup':
            cluster_name => $cluster_name,
        }

        backup::set { 'etcd': }
    }
}
