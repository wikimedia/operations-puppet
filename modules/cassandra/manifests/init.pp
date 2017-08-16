# == Class: cassandra
#
# Installs and configures a Cassandra server
#
# (Much of this module was adapted from:
# https://github.com/msimonin/puppet-cassandra)
#
# Note:  This class requires the Puppet stdlib module, particularly the pick() function.
#
# === Usage
# class { '::cassandra':
#     cluster_name => 'my_cluster',
#     seeds        => ['10.11.12.13', '10.11.13.14'],
#     dc           => 'my_datacenter1',
#     rack         => 'my_rack1',
# #   ...
# }
#
# === Parameters
# [*cluster_name*]
#   The logical name of this Cassandra cluster.
#   Default: Test Cluster
#
# [*instances*]
#   An hash from instance name to several instance-specific parameters,
#   including:
#     * jmx_port        must be unique per-host
#     * listen_address  address to use for cassandra clients
#     * rpc_address     address to use for cassandra cluster traffic
#   See also cassandra::instance
#
#   Unless default behaviour (as in Cassandra's Debian package) is wanted, each
#   instance will have its configuration deployed at /etc/cassandra-<TITLE>
#   with data at /srv/cassandra-<TITLE> and a corresponding nodetool
#   binary named nodetool-<TITLE> to be used to access instances individually.
#   Similarly each instance service will be available under
#   "cassandra-<TITLE>".
#
# [*seeds*]
#   Array of seed IPs for this Cassandra cluster.
#   Default: [$::ipaddress]
#
# [*num_tokens*]
#   Number of tokens randomly assigned to this node on the ring.
#   Default: 256
#
# [*authenticator*]
#   Authentication backend, implementing IAuthenticator; used to identify users.
#   If false, AllowAllAuthenticator will be used.
#   If true, PasswordAuthenticator will be used.
#   Else, the value provided will be used.
#   Default: true
#
# [*authorizor*]
#   Authorization backend, implementing IAuthorizer; used to limit access/provide permissions.
#   If false, AllowAllAuthorizer will be used.
#   If true, CassandraAuthorizer will be used.
#   Else, the value provided will be used.
#   Default: true
#
# [*permissions_validity_in_ms*]
#   Validity period for permissions cache (fetching permissions can be an
#   expensive operation depending on the authorizer, CassandraAuthorizer is
#   one example). Will be disabled automatically for AllowAllAuthorizer.
#   Defaults to 2000, set to 0 to disable.
#
# [*data_directory_base*]
#   The base directory for cassandra data if we use default instance. In case
#   of multi-instances this directory is generated based on the instance name.
#   Default: /var/lib/cassandra
#
# [*data_file_directories*]
#   Array of directories where Cassandra should store data on disk.
#   This module will not set up partitions or RAID, so make sure
#   You have these directories configured as you like and mounted
#   before you apply this module.
#   Default: [/var/lib/cassandra/data]
#
# [*commitlog_directory*]
#   Directory where Cassandra should store its commit log.
#   Default: /var/lib/cassandra/commitlog
#
# [*hints_directory*]
#   Directory where Cassandra stores hints (Cassandra >= 3.0)
#   Default: /var/lib/cassandra/data/hints
#
# [*disk_failure_policy*]
#   Policy for data disk failure.  Should be one of:
#   stop_paranoid, die, stop, best_effort, or ignore.
#   Default: stop
#
# [*row_cache_size_in_mb*]
#   Enable a small cache by default.
#   Default: 200
#
# [*memory_allocator*]
#   The off-heap memory allocator.
#   Default: JEMallocAllocator
#
# [*saved_caches_directory*]
#   Directory where Cassandra should store saved caches.
#   Default: /var/lib/cassandra/saved_caches
#
# [*concurrent_reads*]
#   Number of allowed concurrent reads.
#   Default: 32
#
# [*concurrent_writes*]
#   Number of allowed concurrent writes. Impacts peak memory usage.
#   Default: 32
#
# [*concurrent_counter_writes*]
#   Number of allowed concurrent counter writes.
#   Default: 32
#
# [*trickle_fsync*]
#   Whether or not to enable trickle_fsync.
#   Default: true
#
# [*trickle_fsync_interval_in_kb*]
#   Interval (in kilobytes) when sequential writing to fsync(), forcing
#   the operating system to flush the dirty buffers.
#   Default: 30240
#
# [*storage_port*]
#   TCP port for cluster communication
#   Default: 7000
#
# [*listen_address*]
#   Cassandra listen IP address.  Default $::ipaddress
#
# [*broadcast_address*]
#   IP address to broadcast to other Cassandra nodes.  Default: undef (uses $listen _address)
#
# [*start_native_transport*]
#   Whether to start the native transport server.  Default: true
#
# [*native_transport_port*]
#   Native transport listen port.  Default: 9042
#
# [*start_rpc*]
#   Whether to start the thrift rpc server.  Default: true
#
# [*rpc_address*]
#   IP address to bind the Thrift RPC service and native transport server.  Default: $::ipaddress
#
# [*rpc_port*]
#   Port for Thrift to listen for clients on.  Default: 9160
#
# [*rpc_server_type*]
#   RPC server type, either 'sync' or 'hsha' (half sync, half async).  Default: sync
#
# [*incremental_backups*]
#   If true, Cassandra will create incremental hardlink backups.
#   Default: false
#
# [*snapshot_before_compaction*]
#   Whether or not to take a snapshot before each compaction.
#   Default: false
#
# [*auto_snapshot*]
#   Whether or not a snapshot is taken of the data before keyspace
#   truncation or dropping of column families.
#   Default: true
#
# [*compaction_throughput_mb_per_sec*]
#    Throttles compaction to the given total throughput across
#    the entire system.
#    Default: 16
#
# [*concurrent_compactors*]
#    Number of simultaneous compactions to allow.
#    Default: 1
#
# [*streaming_socket_timeout_in_ms*]
#    Number of milliseconds required to time out streaming connections.
#    Default: 0 (disabled)
#
# [*endpoint_snitch*]
#   Set this to a class that implements IEndpointSnitch.
#   Default: GossipingPropertyFileSnitch
#
# [*internode_compression*]
#   Controls whether traffic between nodes is compressed.
#   Should be one of: all, dc, or none
#   Default: all
#
# [*max_heap_size*]
#   Value for -Xms and -Xmx to pass to the JVM. Example: '8g'
#   Default: undef
#
# [*heap_newsize*]
#   Value for -Xmn to pass to the JVM. Example: '1200m'
#   Default: undef
#
# [*additional_jvm_opts*]
#   Additional options to pass to the JVM.
#   Default: []
#
# [*extra_classpath*]
#   Additional files and/or directories to append to the JVM classpath.
#   Default: []
#
# [*jmx_port*]
#   Port to listen for JMX queries.
#   Default: 7199
#
# [*dc*]
#   Logical name datacenter name.  This will only be used
#   if $endpoint_snitch is GossipingPropertyFileSnitch.
#   Default:  dc1
#
# [*rack*]
#   Logical rack name.  This will only be used
#   if $endpoint_snitch is GossipingPropertyFileSnitch.
#   Default rack1
#
# [*key_cache_size_in_mb*]
#   Maximum size of the key cache in memory.
#   Default: empty (aka "auto" (min(5% of heap (in MB), 100MB)))
#
# [*tls_cluster_name*]
#   If specified, use private keys (client and server) from private.git
#   belonging to this cluster. Also install the cluster's CA as trusted.
#   Default: undef
#
# [*internode_encryption*]
#   What level of inter node encryption to enable
#   Default: none
#
# [*client_encryption_enabled*]
#   Enable client-side encryption
#   Default: false
#
# [*super_username*]
#   Cassandra superuser username.
#   Username and password for superuser will be written to
#   /etc/cassandra/cqlshrc for easy/unattended usage by cqlsh.
#   Default: cassandra
#
# [*super_password*]
#   Cassandra superuser password.
#   Default: cassandra
#
# [*application_username*]
#   Non-superuser user; Username for application access.
#   Default: undef
#
#   If set, a CQL file will be created in /etc/cassandra/adduser.cql to
#   provision the respective user and grants with cqlsh:
#
#   cqlsh --cqlshrc=/etc/cassandra/cqlshrc -f /etc/cassandra/adduser.cql $HOSTNAME
#
# [*application_password*]
#   Password for application user.
#   Default: undef
#
# [*auto_bootstrap*]
#   Control whether new nodes joining the cluster will get data they own.
#   Default: true
#
# [*target_version*]
#   The Cassandra version to configure for.  Valid choices are '2.1', '2.2', and '3.x'.
#   Default: 2.1

class cassandra (
    $cluster_name            = 'Test Cluster',
    $tls_cluster_name        = undef,
    $instances               = undef,
    $default_instance_params = {},
    $seeds                   = [$::ipaddress],
    $listen_address          = $::ipaddress,
    $additional_jvm_opts     = [],
    $extra_classpath         = [],
    $target_version          = '2.1',
    $memory_allocator        = 'JEMallocAllocator',
    $application_username    = undef,
    $application_password    = undef,
    $native_transport_port   = 9042,
    $dc                      = 'datacenter1',
    $rack                    = 'rack1',
    $logstash_host           = 'logstash1003.eqiad.wmnet',
    $logstash_port           = 11514,
    $start_rpc               = true,
) {
    validate_string($cluster_name)

    validate_array($extra_classpath)


    if (!($target_version in ['2.1', '2.2', '3.x'])) {
        fail("${target_version} is not a valid Cassandra target version!")
    }

    package { 'openjdk-8-jdk':
        ensure  => 'installed',
    }

    # Cassandra and JVM utils
    package { 'cassandra-tools-wmf':
        ensure  => 'installed',
        require => Package['cassandra'],
    }
    package { 'jvm-tools':
        ensure  => 'installed',
        require => Package['openjdk-8-jdk'],
    }

    # We pin the version to a specific one
    $package_version = $target_version ? {
        '2.1' => hiera('cassandra::version', '2.1.13'),
        '2.2' => hiera('cassandra::version', '2.2.6-wmf1'),
        '3.x' => hiera('cassandra::version', '3.11.0'),
    }
    package { 'cassandra':
        ensure  => $package_version,
        require => Package['openjdk-8-jdk'],
    }

    # Make sure libjemalloc is installed if
    # we are going to use the JEMallocAllocator.
    if $memory_allocator == 'JEMallocAllocator' {
        package { 'libjemalloc1':
            ensure => 'installed',
        }
    }

    # Create non-default cassandra instances if requested.
    # Default is to keep Debian package behaviour,
    # in other words create a "default" instance.
    if empty($instances) {
        $instances_to_create = {
            'default' => {
                config_directory       => '/etc/cassandra',
                service_name           => 'cassandra',
                tls_hostname           => $::hostname,
                pid_file               => '/var/run/cassandra/cassandra.pid',
                instance_id            => $::hostname,
                jmx_port               => 7199,
                data_directory_base    => '/var/lib/cassandra',
                data_file_directories  => ['/var/lib/cassandra/data'],
                commitlog_directory    => '/var/lib/cassandra/commitlog',
                hints_directory        => '/var/lib/cassandra/data/hints',
                heapdump_directory     => '/var/lib/cassandra/',
                saved_caches_directory => '/var/lib/cassandra/saved_caches',
            }
        }
    } else {
        $instances_to_create = $instances
    }

    create_resources(
        cassandra::instance,
        $instances_to_create,
        # pass defaults from the main cassandra class
        merge(
            $default_instance_params,
            {
                cluster_name          => $cluster_name,
                tls_cluster_name      => $tls_cluster_name,
                seeds                 => $seeds,
                additional_jvm_opts   => $additional_jvm_opts,
                extra_classpath       => $extra_classpath,
                memory_allocator      => $memory_allocator,
                listen_address        => $listen_address,
                tls_cluster_name      => $tls_cluster_name,
                application_username  => $application_username,
                application_password  => $application_password,
                native_transport_port => $native_transport_port,
                target_version        => $target_version,
                dc                    => $dc,
                rack                  => $rack,
                logstash_host         => $logstash_host,
                logstash_port         => $logstash_port,
                start_rpc             => $start_rpc,
            }
        )
    )

    # if running multi-instances, make sure the default instance is stopped
    if !empty($instances) {
        service { 'cassandra':
            ensure => stopped,
        }
    }

    # nodetool wrapper to handle multiple instances, for each instance there
    # will be symlinks from /usr/local/bin/nodetool-<INSTANCE_NAME> to
    # nodetool-instance
    file { '/usr/local/bin/nodetool-instance':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/nodetool-instance",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0555',
        require => Package['cassandra'],
    }

    file { '/etc/cassandra.in.sh':
        ensure  => present,
        content => template("${module_name}/cassandra.in.sh.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    # no-op sysv init script
    file { '/etc/init.d/cassandra':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/cassandra-init.d",
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['cassandra'],
    }

    file { '/etc/tmpfiles.d/cassandra.conf':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/cassandra-tmpfiles.conf",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    file { '/etc/cassandra-instances.d':
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0755',
        require => Package['cassandra'],
    }

    scap::target { 'prometheus/jmx_exporter':
        deploy_user => 'deploy-service',
        manage_user => true,
    }
}
