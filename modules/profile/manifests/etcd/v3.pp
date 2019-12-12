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
        $certname = "_etcd-server-ssl._tcp.${srv_dns}"
    } else {
        $peers_list = $discovery
        $srv_dns = undef
        $certname = $::fqdn
    }

    $adv_client_port = 4001

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
        adv_client_port  => $adv_client_port,
        trusted_ca       => '/etc/ssl/certs/Puppet_Internal_CA.pem',
        client_cert      => "/etc/ssl/localcerts/${certname}.crt",
        client_key       => "/etc/ssl/private/${certname}.key",
        peer_cert        => "/etc/ssl/localcerts/${certname}.crt",
        peer_key         => "/etc/ssl/private/${certname}.key",
    }

    # Monitoring
    class { '::etcd::v3::monitoring':
        endpoint => "https://${::fqdn}:2379"
    }

    # Firewall
    if $allow_from != 'localhost' {
        ferm::service { 'etcd_clients':
            proto  => 'tcp',
            port   => $adv_client_port,
            srange => $allow_from,
        }
    }

    ferm::service { 'etcd_peers':
        proto  => 'tcp',
        port   => 2380,
        srange => '$DOMAIN_NETWORKS',
    }

    # TLS certs *for etcd use* in peer-to-peer communications.
    # Tlsproxy will use other certificates.

    sslcert::certificate { $certname:
        skip_private => false,
        group        => 'etcd',
        require      => Package['etcd-server'],
        before       => Service['etcd'],
    }

}
