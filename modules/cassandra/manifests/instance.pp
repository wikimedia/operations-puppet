# == Define: cassandra::instance
#
# Installs and configures a Cassandra server instance
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
# [*storage_port*]
#   TCP port, for commands and data.
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

define cassandra::instance(
) {
    $instance_name = $title
    $instances = hiera('cassandra::instances')
    if ! has_key($instances, $instance_name) {
        fail("instance $instance_name not found in $instances")
    }

    $this_instance = $instances[$instance_name]
    $jmx_port = $this_instance['jmx_port']
    $listen_address = $this_instance['listen_address']
    $rpc_address = $this_instance['rpc_address']

    if $instance_name == "default" {
        $data_directory_base = '/var/lib/cassandra'
        $config_directory    = '/etc/cassandra'
        $service_name        = 'cassandra'
        $pid_file            = '/var/run/cassandra/cassandra.pid'
    } else {
        $data_directory_base = "/var/lib/cassandra-${instance_name}"
        $config_directory    = "/etc/cassandra-${instance_name}"
        $service_name        = "cassandra-${instance_name}"
        $pid_file            = "/var/run/cassandra/cassandra-${instance_name}.pid"
    }

    $data_file_directories  = ["${data_directory_base}/data"]
    $commitlog_directory    = "${data_directory_base}/commitlog"
    $heapdump_directory     = "${data_directory_base}/"
    $saved_caches_directory = "${data_directory_base}/saved_caches"

    file { $config_directory:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => Package['cassandra'],
    }

    file { $data_directory_base:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => Package['cassandra'],
    }

    file { $data_file_directories:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => File[$data_directory_base],
    }

    file { $commitlog_directory:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => File[$data_directory_base],
    }

    file { $saved_caches_directory:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => File[$data_directory_base],
    }

    file { "${config_directory}/cassandra-env.sh":
        content => template("${module_name}/cassandra-env.sh.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => File[$config_directory],
    }

    file { "${config_directory}/cassandra.yaml":
        content => template("${module_name}/cassandra.yaml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => File[$config_directory],
    }

    file { "${config_directory}/cassandra-rackdc.properties":
        ensure  => present,
        content => template("${module_name}/cassandra-rackdc.properties.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => File[$config_directory],
    }

    if $instance_name != "default" {
        file { "/usr/local/bin/nodetool-${instance_name}":
            ensure  => link,
            target  => '/usr/local/bin/nodetool-instance',
            require => File['/usr/local/bin/nodetool-instance'],
        }
    }

    base::service_unit { $service_name:
        ensure        => present,
        template_name => 'cassandra',
        systemd       => true,
        refresh       => false,
        require       => [
            File[$data_file_directories],
            File["${config_directory}/cassandra-env.sh"],
            File["${config_directory}/cassandra.yaml"],
            File["${config_directory}/cassandra-rackdc.properties"],
        ],
    }
}
