# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure swift storage
# @param disks_by_path if true configure drives using the pci path
class profile::swift::storage (
    Array[String] $aux_partitions                       = lookup('swift_aux_partitions'),
    Array[String] $all_drives                           = lookup('swift_storage_drives'),
    Hash[String, Hash] $replication_accounts            = lookup('profile::swift::replication_accounts'),
    Hash[String, Hash] $replication_keys                = lookup('profile::swift::replication_keys'),
    String $hash_path_suffix                            = lookup('profile::swift::hash_path_suffix'),
    Array[String] $memcached_servers                    = lookup('profile::swift::proxy::memcached_servers'),
    Array[Stdlib::Host] $swift_backends                 = lookup('profile::swift::storagehosts'),
    Array[Stdlib::Host] $swift_frontends                = lookup('profile::swift::proxyhosts'),
    Stdlib::Port $statsd_port                           = lookup('profile::swift::storage::statsd_port'),
    Integer $container_replicator_concurrency           = lookup('profile::swift::storage::container_replicator_concurrency'),
    Integer $object_server_default_workers              = lookup('profile::swift::storage::object_server_default_workers'),
    Integer $object_replicator_concurrency              = lookup('profile::swift::storage::object_replicator_concurrency'),
    Optional[Integer] $object_replicator_interval       = lookup('profile::swift::storage::object_replicator_interval'),
    Optional[Integer] $servers_per_port                 = lookup('profile::swift::storage::servers_per_port'),
    Optional[Stdlib::Host] $statsd_host                 = lookup('profile::swift::storage::statsd_host'),
    Optional[Integer] $container_replicator_interval    = lookup('profile::swift::storage::container_replicator_interval'),
    Optional[Integer] $replication_limit_memory_percent = lookup('profile::swift::storage::replication_limit_memory_percent'),
    Optional[String] $loopback_device_size              = lookup('profile::swift::storage::loopback_device_size'),
    Optional[Integer] $loopback_device_count            = lookup('profile::swift::storage::loopback_device_count'),
    Boolean $disable_fallocate                          = lookup('profile::swift::storage::disable_fallocate'),
    Boolean $disks_by_path                              = lookup('profile::swift::storage::disks_by_path'),
    Hash[String, Hash] $global_account_keys            = lookup('profile::swift::global_account_keys'),
    Swift::Clusters $swift_clusters                     = lookup('swift_clusters'),
    String $swift_cluster_label                         = lookup('profile::swift::cluster_label'),

){

    $site_backends = $swift_backends.filter |$host| { $host =~ Regexp("${::domain}$") }

    class { 'swift':
        hash_path_suffix => $hash_path_suffix,
    }

    $swift_cluster_name = $swift_clusters[$swift_cluster_label]['cluster_name']

    class { 'swift::ring':
        swift_cluster => $swift_cluster_name,
    }

    class { 'swift::storage':
        statsd_host                      => $statsd_host,
        statsd_port                      => $statsd_port,
        statsd_metric_prefix             => "swift.${swift_cluster_name}.${::hostname}",
        memcached_servers                => $memcached_servers,
        container_replicator_concurrency => $container_replicator_concurrency,
        object_server_default_workers    => $object_server_default_workers,
        object_replicator_concurrency    => $object_replicator_concurrency,
        object_replicator_interval       => $object_replicator_interval,
        servers_per_port                 => $servers_per_port,
        container_replicator_interval    => $container_replicator_interval,
        backends                         => $site_backends,
        replication_limit_memory_percent => $replication_limit_memory_percent,
        loopback_device_size             => $loopback_device_size,
        loopback_device_count            => $loopback_device_count,
        disable_fallocate                => $disable_fallocate,
    }

    class { 'swift::container_sync':
        accounts => $replication_accounts,
        keys     => $replication_keys,
    }

    $rclone_ensure = $swift_clusters[$swift_cluster_label]['rclone_host'] ? {
        $facts['networking']['fqdn'] => 'present',
        default => 'absent',
    }

    class { 'swift::rclone':
        ensure      => $rclone_ensure,
        credentials => $global_account_keys,
    }

    $expirer_ensure = $swift_clusters[$swift_cluster_label]['expirer_host'] ? {
        $facts['networking']['fqdn'] => 'present',
        default => 'absent',
    }

    class { 'swift::expirer':
        ensure               => $expirer_ensure,
        statsd_metric_prefix => "swift.${swift_cluster_name}.${::hostname}",
        memcached_servers    => $memcached_servers,
    }

    nrpe::monitor_service { 'load_average':
        description  => 'very high load average likely xfs',
        nrpe_command => '/usr/lib/nagios/plugins/check_load -w 80,80,80 -c 200,100,100',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Swift',
    }

    if $disks_by_path {
        class { 'profile::swift::storage::configure_disks':
            swift_storage_dir => $swift::storage::swift_data_dir,
        }
    } else {
        swift::init_device { $all_drives:
            partition_nr => '1',
        }
        # these are already partitioned and xfs formatted by the installer
        swift::label_filesystem { $aux_partitions: }
        swift::mount_filesystem { $aux_partitions: }
    }

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

}
