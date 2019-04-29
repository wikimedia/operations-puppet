# filtertags: labs-project-deployment-prep labs-project-swift
class role::swift::storage {
    system::role { 'swift::storage':
        description => 'swift storage brick',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::swift::params
    include ::swift
    include ::swift::ring
    class { '::swift::storage':
        statsd_metric_prefix => "swift.${::swift::params::swift_cluster}.${::hostname}",
        memcached_servers    => hiera('swift::proxy::memcached_servers'),
    }
    include ::swift::container_sync
    include ::swift::storage::monitoring

    include ::toil::systemd_scope_cleanup

    include ::profile::statsite
    class { '::profile::prometheus::statsd_exporter':
        relay_address => 'localhost:8125',
    }

    $all_drives = hiera('swift_storage_drives')

    swift::init_device { $all_drives:
        partition_nr => '1',
    }

    $swift_backends = hiera('swift::storagehosts')
    $swift_frontends = hiera('swift::proxyhosts')
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

    # these are already partitioned and xfs formatted by the installer
    $aux_partitions = hiera('swift_aux_partitions')
    swift::label_filesystem { $aux_partitions: }
    swift::mount_filesystem { $aux_partitions: }
}
