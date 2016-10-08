class profile::swift::storage {

    # Global variables
    $statsd_host = hiera('statsd_host', 'localhost')

    # Swift-wide variables
    $cluster_name = hiera('swift::cluster', "${::site}-prod")
    $swift_backends = hiera('swift::storagehosts')
    $swift_frontends = hiera('swift::proxyhosts')

    # Local per-machine variables (can be set per-host or with a regex)
    $all_drives = hiera('swift_storage_drives')
    # these are already partitioned and xfs formatted by the installer
    $aux_partitions = hiera('swift_aux_partitions')


    class { '::swift::storage':
        statsd_host          => $statsd_host,
        statsd_metric_prefix => "swift.${cluster_name}.${::hostname}",
    }

    class { '::swift::storage::monitoring': }

    swift::init_device { $all_drives:
        partition_nr => '1',
    }

    $swift_access = concat($swift_backends, $swift_frontends)
    $swift_access_ferm = join($swift_access, ' ')
    $swift_rsync_access_ferm = join($swift_backends, ' ')

    ferm::service { 'swift-object-server':
        proto   => 'tcp',
        port    => '6000',
        notrack => true,
        srange  => "@resolve((${swift_access_ferm}))",
    }

    ferm::service { 'swift-container-server':
        proto   => 'tcp',
        port    => '6001',
        notrack => true,
        srange  => "@resolve((${swift_access_ferm}))",
    }

    ferm::service { 'swift-account-server':
        proto   => 'tcp',
        port    => '6002',
        notrack => true,
        srange  => "@resolve((${swift_access_ferm}))",
    }

    ferm::service { 'swift-rsync':
        proto   => 'tcp',
        port    => '873',
        notrack => true,
        srange  => "@resolve((${swift_rsync_access_ferm}))",
    }

    swift::label_filesystem { $aux_partitions: }
    swift::mount_filesystem { $aux_partitions: }
}
