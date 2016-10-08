# Manages a base installation of swift on a server.
# No further configuration is done in order to configure
# storage or proxy components.
class profile::swift::base {
    $hash_path_suffix = hiera('swift::hash_path_suffix')
    $cluster_name = hiera('swift::cluster', "${::site}-prod")
    $replication_accounts = hiera('swift::replication_accounts')
    $replication_keys = hiera('swift::replication_keys')

    class { '::swift':
        hash_path_suffix => $hash_path_suffix,
        swift_cluster    => $cluster_name,
    }

    class { '::swift::ring':
        swift_cluster => $cluster_name,
    }

    class { '::swift::container_sync':
        replication_accounts => $replication_accounts,
        replication_keys     => $replication_keys,
    }


}
