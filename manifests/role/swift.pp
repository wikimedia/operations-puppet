@monitoring::group { 'swift':
    description => 'swift servers',
}


class role::swift::stats_reporter {
    system::role { 'role::swift::stats_reporter':
        description => 'swift statistics reporter',
    }

    include standard
    include ::swift::params
    include ::swift::stats::dispersion
    include ::swift::stats::accounts
}

class role::swift::proxy {
    system::role { 'role::swift::proxy':
        description => 'swift frontend proxy',
    }

    include standard
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

    ferm::service { 'swift-proxy':
        proto  => 'tcp',
        notrack => true,
        port   => '80',
    }

    $swift_frontends = hiera('swift::proxyhosts')
    $swift_frontends_ferm = join($swift_frontends, ' ')

    # Access to memcached from swift frontends
    ferm::service { 'swift-memcached':
        proto   => 'tcp',
        port    => '11211',
        notrack => true,
        srange  => "@resolve(($swift_frontends_ferm))",
    }

    monitoring::service { 'swift-http-frontend':
        description   => 'Swift HTTP frontend',
        check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/frontend",
    }
    monitoring::service { 'swift-http-backend':
        description   => 'Swift HTTP backend',
        check_command => "check_http_url!${::swift::proxy::proxy_service_host}!/monitoring/backend",
    }
}


class role::swift::storage {
    system::role { 'role::swift::storage':
        description => 'swift storage brick',
    }

    include standard
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
