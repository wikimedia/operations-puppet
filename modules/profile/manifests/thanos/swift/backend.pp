class profile::thanos::swift::backend (
    Array $thanos_backends = lookup('profile::thanos::backends'),
    Array $thanos_frontends = lookup('profile::thanos::frontends'),
    String $swift_cluster = lookup('profile::thanos::swift::cluster'),
    Array $memcached_servers = lookup('profile::thanos::swift::memcached_servers'),
    String $hash_path_suffix = lookup('profile::thanos::swift::hash_path_suffix'),
    Array $drives = lookup('swift_storage_drives'),
    Array $aux_partitions = lookup('swift_aux_partitions'),
) {
    class { '::swift':
        hash_path_suffix => $hash_path_suffix,
    }

    class { '::swift::ring':
        swift_cluster => $swift_cluster,
    }

    class { '::swift::storage':
        statsd_metric_prefix => "swift.${swift_cluster}.${::hostname}",
        memcached_servers    => $memcached_servers,
    }

    class { '::toil::systemd_scope_cleanup': }

    include ::profile::statsite
    class { '::profile::prometheus::statsd_exporter':
        relay_address => '',
    }

    nrpe::monitor_service { 'load_average':
        description  => 'very high load average likely xfs',
        nrpe_command => '/usr/lib/nagios/plugins/check_load -w 80,80,80 -c 200,100,100',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Swift',
    }

    swift::init_device { $drives:
        partition_nr => '1',
    }

    # these are already partitioned and xfs formatted by the installer
    swift::label_filesystem { $aux_partitions: }
    swift::mount_filesystem { $aux_partitions: }

    $swift_access = concat($thanos_backends, $thanos_frontends)
    $swift_access_ferm = join($swift_access, ' ')
    $swift_rsync_access_ferm = join($thanos_backends, ' ')

    # Optimize ferm rule aggregating all ports, it includes:
    # - base object server (6000)
    # - container server (6001)
    # - account server (6002)
    # - per-disk object-server ports T222366 (6010:6040)
    ferm::service { 'swift-object-server':
        proto   => 'tcp',
        port    => '(6000:6002 6010:6040)',
        notrack => true,
        srange  => "@resolve((${swift_access_ferm}))",
    }

    ferm::service { 'swift-rsync':
        proto   => 'tcp',
        port    => '873',
        notrack => true,
        srange  => "@resolve((${swift_rsync_access_ferm}))",
    }
}
