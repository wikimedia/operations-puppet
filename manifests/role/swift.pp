@monitoring::group { 'swift':
    description => 'swift servers',
}


class role::swift::stats_reporter {
    include role::swift::base

    system::role { 'role::swift::stats_reporter':
        description => 'swift statistics reporter',
    }

    include ::swift::params
    include ::swift::stats::dispersion
    include ::swift::stats::accounts
}

class role::swift::proxy {
    include role::swift::base

    system::role { 'role::swift::proxy':
        description => 'swift frontend proxy',
    }

    include ::swift::params
    include ::swift
    include ::swift::ring
    include ::swift::container_sync

    class { '::swift::proxy':
        statsd_metric_prefix => "swift.${::swift::params::swift_cluster}.${::hostname}",
    }

    class { '::memcached':
        size => 128,
        port => 11211,
    }

    include role::statsite

    monitoring::service { 'swift-http-frontend':
        description   => 'Swift HTTP frontend',
        check_command => "check_http_url!${swift_check_http_host}!/monitoring/frontend",
    }
    monitoring::service { 'swift-http-backend':
        description   => 'Swift HTTP backend',
        check_command => "check_http_url!${swift_check_http_host}!/monitoring/backend",
    }
}


class role::swift::storage {
    include role::swift::base

    system::role { 'role::swift::storage':
        description => 'swift storage brick',
    }

    include ::swift::params
    include ::swift
    include ::swift::ring
    class { '::swift::storage':
        statsd_metric_prefix => "swift.${::swift::params::swift_cluster}.${::hostname}",
    }
    include ::swift::container_sync
    include ::swift::storage::monitoring

    include role::statsite

    $all_drives = hiera('swift_storage_drives')

    swift::init_device { $all_drives:
        partition_nr => '1',
    }

    # these are already partitioned and xfs formatted by the installer
    $aux_partitions = hiera('swift_aux_partitions')
    swift::label_filesystem { $aux_partitions: }
    swift::mount_filesystem { $aux_partitions: }
}
