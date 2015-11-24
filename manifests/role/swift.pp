class role::swift::stats_reporter {
    system::role { 'role::swift::stats_reporter':
        description => 'swift statistics reporter',
    }

    include standard
    include ::swift::params
    include ::swift::stats::dispersion
    include ::swift::stats::accounts

    swift::stats::stats_container { 'mw-media':
        account_name  => 'AUTH_mw',
        container_set => 'mw-media',
        statsd_prefix => "swift.${::swift::params::swift_cluster}.containers.mw-media",
    }
}

class role::swift::proxy {
    system::role { 'role::swift::proxy':
        description => 'swift frontend proxy',
    }

    include standard
    include base::firewall
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

    ferm::service { 'swift-memcached':
        proto   => 'tcp',
        port    => '11211',
        notrack => true,
        srange  => "@resolve((${swift_frontends_ferm}))",
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
    include base::firewall
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
