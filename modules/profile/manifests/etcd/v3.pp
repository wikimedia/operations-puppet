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
# [*use_pki_certs]
#   Boolean. Whether to use the CFSSL based PKI to generate certificates,
#   or to use the older Puppet CA based certificates. Defaults to false.
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
    Boolean $use_pki_certs = lookup('profile::etcd::v3::use_pki_certs', {'default_value' => false}),
    Array[Stdlib::Host] $prometheus_all_nodes = lookup('prometheus_all_nodes'),
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

    # TLS certs *for etcd use* in peer-to-peer communications,
    # tlsproxy will use other certificates.
    # According to https://github.com/etcd-io/etcd/commit/4e21f87e3d014d606bb3ba2a89731a7d24806611
    # etcd does reload the certificate from disc for every client
    # connection. So there is no need to notify the etcd service
    # on certificate renewals.

    # This option uses the puppet CA based certificates
    if ! $use_pki_certs {
        sslcert::certificate { $certname:
            skip_private => false,
            group        => 'etcd',
            require      => Package['etcd-server'],
            before       => Service['etcd'],
        }

        $ssl_paths = {
            'chained' => "/etc/ssl/localcerts/${certname}.crt",
            'key'     => "/etc/ssl/private/${certname}.key",
        }
    }
    # This option allows the CFSSL based PKI to be used with the etcd intermediate
    else {
        # From etcd 3.3+ (bullseye version+) if we use discovery SRV records,
        # we'll also need to add a SAN with the "domain_name: in "dns:domain_name"
        # See T329556
        if debian::codename::ge('bullseye') and $srv_dns != undef {
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
    }

    # Service
    class { '::etcd::v3':
        cluster_name     => $cluster_name,
        cluster_state    => $cluster_state,
        srv_dns          => $srv_dns,
        peers_list       => $peers_list,
        use_client_certs => $use_client_certs,
        max_latency_ms   => $max_latency,
        adv_client_port  => $adv_client_port,
        trusted_ca       => profile::base::certificates::get_trusted_ca_path(),
        client_cert      => $ssl_paths['chained'],
        client_key       => $ssl_paths['key'],
        peer_cert        => $ssl_paths['chained'],
        peer_key         => $ssl_paths['key'],
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

    firewall::service { 'etcd_prometheus':
        proto  => 'tcp',
        port   => $adv_client_port,
        srange => $prometheus_all_nodes,
    }

    ferm::service { 'etcd_peers':
        proto  => 'tcp',
        port   => 2380,
        srange => '$DOMAIN_NETWORKS',
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
