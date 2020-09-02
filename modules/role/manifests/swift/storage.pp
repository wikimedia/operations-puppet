# filtertags: labs-project-deployment-prep labs-project-swift
class role::swift::storage (
    Hash[String, Hash] $replication_accounts = lookup('profile::swift::replication_accounts'), # lint:ignore:wmf_styleguide
    Hash[String, Hash] $replication_keys = lookup('profile::swift::replication_keys'), # lint:ignore:wmf_styleguide
    String $hash_path_suffix = lookup('profile::swift::hash_path_suffix'), # lint:ignore:wmf_styleguide
) {
    system::role { 'swift::storage':
        description => 'swift storage brick',
    }

    $swift_cluster = lookup('profile::swift::cluster') # lint:ignore:wmf_styleguide

    include ::profile::standard
    include ::profile::base::firewall

    class { '::swift':
        hash_path_suffix => $hash_path_suffix,
    }

    class { '::swift::ring':
        swift_cluster => $swift_cluster,
    }

    class { '::swift::storage':
        statsd_metric_prefix          => "swift.${swift_cluster}.${::hostname}",
        memcached_servers             => hiera('swift::proxy::memcached_servers'),
        object_replicator_concurrency => hiera('swift::storage::object_replicator_concurrency'),  # lint:ignore:wmf_styleguide
        object_replicator_interval    => hiera('swift::storage::object_replicator_interval', undef),  # lint:ignore:wmf_styleguide
        servers_per_port              => hiera('swift::storage::servers_per_port', undef),  # lint:ignore:wmf_styleguide
    }

    class { '::swift::container_sync':
        accounts => $replication_accounts,
        keys     => $replication_keys,
    }

    include ::toil::systemd_scope_cleanup

    include ::profile::statsite
    class { '::profile::prometheus::statsd_exporter':
        relay_address => '',
    }

    nrpe::monitor_service { 'load_average':
        description  => 'very high load average likely xfs',
        nrpe_command => '/usr/lib/nagios/plugins/check_load -w 80,80,80 -c 200,100,100',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Swift',
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

    # these are already partitioned and xfs formatted by the installer
    $aux_partitions = hiera('swift_aux_partitions')
    swift::label_filesystem { $aux_partitions: }
    swift::mount_filesystem { $aux_partitions: }
}
