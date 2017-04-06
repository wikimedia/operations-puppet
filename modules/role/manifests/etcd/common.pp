# Common class for all etcd clusters. Should be a profile
# in the role/profile view
#
# filtertags: labs-project-deployment-prep
class role::etcd::common {
    # Configuration
    $cluster_name = hiera('etcd::cluster_name', $::domain)
    $cluster_state = hiera('etcd::cluster_state', 'existing')
    $srv_dns = hiera('etcd::srv_dns', undef)
    $use_client_certs = hiera('etcd::use_client_certs', undef)
    $peers_list = hiera('etcd::peers_list', undef)
    $allowed_networks = hiera('etcd::allowed_networks', '$DOMAIN_NETWORKS')
    $do_backup = hiera('etcd::do_backup', false)
    $auth_enabled = hiera('etcd::auth_enabled', false)
    $root_password = hiera('etcd::auth::common::root_password', undef)

    # Service & firewalls
    class { '::etcd':
        host             => $::fqdn,
        cluster_name     => $cluster_name,
        cluster_state    => $cluster_state,
        srv_dns          => $srv_dns,
        peers_list       => $peers_list,
        use_ssl          => true,
        use_client_certs => $use_client_certs,
    }

    include etcd::monitoring
    ferm::service{'etcd_clients':
        proto  => 'tcp',
        port   => hiera('etcd::client_port', '2379'),
        srange => $allowed_networks,
    }

    ferm::service{'etcd_peers':
        proto  => 'tcp',
        port   => hiera('etcd::peer_port', '2380'),
        srange => '$DOMAIN_NETWORKS',
    }

    # Backup
    if $do_backup {
        # Back up etcd
        class { '::etcd::backup':
            cluster_name => $cluster_name,
        }
        include profile::backup::host
        backup::set { 'etcd': }
    }

    # Authn/authz
    class { '::etcd::client::globalconfig':
        host       => $::fqdn,
        port       => 2379,
        srv_domain => $srv_dns,
    }

    class { '::etcd::auth::common':
        root_password => $root_password,
        active        => $auth_enabled,

    }
    class { '::etcd::auth': }
    class { '::etcd::auth::users': }
}
