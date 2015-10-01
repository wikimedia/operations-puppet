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
#   Additional classpath to be appended to the default.
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

class cassandra(
    $cluster_name                     = 'Test Cluster',
    $seeds                            = [$::ipaddress],
    $num_tokens                       = 256,
    $authenticator                    = true,
    $authorizor                       = true,
    $data_file_directories            = ['/var/lib/cassandra/data'],
    $commitlog_directory              = '/var/lib/cassandra/commitlog',
    $disk_failure_policy              = 'stop',
    $row_cache_size_in_mb             = 200,
    $memory_allocator                 = 'JEMallocAllocator',
    $saved_caches_directory           = '/var/lib/cassandra/saved_caches',
    $concurrent_reads                 = 32,
    $concurrent_writes                = 32,
    $concurrent_counter_writes        = 32,
    $storage_port                     = 7000,
    $listen_address                   = $::ipaddress,
    $broadcast_address                = undef,
    $start_native_transport           = true,
    $native_transport_port            = 9042,
    $start_rpc                        = true,
    $rpc_address                      = $::ipaddress,
    $rpc_port                         = 9160,
    $rpc_server_type                  = 'sync',
    $incremental_backups              = false,
    $snapshot_before_compaction       = false,
    $auto_snapshot                    = true,
    $compaction_throughput_mb_per_sec = 16,
    $concurrent_compactors            = 1,
    $endpoint_snitch                  = 'GossipingPropertyFileSnitch',
    $internode_compression            = 'all',
    $max_heap_size                    = undef,
    $heap_newsize                     = undef,
    $jmx_port                         = 7199,
    $additional_jvm_opts              = [],
    $extra_classpath                  = [],
    $dc                               = 'datacenter1',
    $rack                             = 'rack1',
    $key_cache_size_in_mb             = 400,
    $tls_cluster_name                 = undef,
    $internode_encryption             = none,
    $client_encryption_enabled        = false,
    $super_username                   = 'cassandra',
    $super_password                   = 'cassandra',
    $application_username             = undef,
    $application_password             = undef,
    $auto_bootstrap                   = true,

    $yaml_template                    = "${module}/cassandra.yaml.erb",
    $env_template                     = "${module}/cassandra-env.sh.erb",
    $rackdc_template                  = "${module}/cassandra-rackdc.properties.erb",
) {
    validate_string($cluster_name)

    validate_absolute_path($commitlog_directory)
    validate_absolute_path($saved_caches_directory)

    validate_string($initial_token)
    validate_string($endpoint_snitch)

    validate_re($rpc_server_type, '^(hsha|sync|async)$')
    # lint:ignore:only_variable_string
    validate_re("${concurrent_reads}", '^[0-9]+$')
    validate_re("${concurrent_writes}", '^[0-9]+$')
    validate_re("${num_tokens}", '^[0-9]+$')
    # lint:endignore
    validate_re($internode_compression, '^(all|dc|none)$')
    validate_re($disk_failure_policy, '^(stop|best_effort|ignore)$')

    validate_array($additional_jvm_opts)
    validate_array($extra_classpath)

    if (!is_integer($jmx_port)) {
        fail('jmx_port must be a port number between 1 and 65535')
    }

    if (!is_ip_address($listen_address)) {
        fail('listen_address must be an IP address')
    }

    if (!empty($broadcast_address) and !is_ip_address($broadcast_address)) {
        fail('broadcast_address must be an IP address')
    }

    if (!is_ip_address($rpc_address)) {
        fail('rpc_address must be an IP address')
    }

    if (!is_integer($rpc_port)) {
        fail('rpc_port must be a port number between 1 and 65535')
    }

    if (!is_integer($native_transport_port)) {
        fail('native_transport_port must be a port number between 1 and 65535')
    }

    if (!is_integer($storage_port)) {
        fail('storage_port must be a port number between 1 and 65535')
    }

    if (!is_array($seeds) or empty($seeds)) {
        fail('seeds must be an array and not be empty')
    }

    if (empty($data_file_directories)) {
        fail('data_file_directories must not be empty')
    }


    # Choose real authenticator and authorizor values
    $authenticator_value = $authenticator ? {
        true    => 'PasswordAuthenticator',
        false   => 'AllowAllAuthenticator',
        default => $authenticator,
    }
    $authorizor_value = $authorizor ? {
        true    => 'CassandraAuthorizer',
        false   => 'AllowAllAuthorizer',
        default => $authorizor,
    }

    package { 'openjdk-8-jdk':
        ensure  => 'installed',
    }

    package { 'cassandra':
        ensure  => 'installed',
        require => Package['openjdk-8-jdk'],
    }

    # Make sure libjemalloc is installed if
    # we are going to use the JEMallocAllocator.
    if $memory_allocator == 'JEMallocAllocator' {
        package { 'libjemalloc1':
            ensure => 'installed',
        }
    }

    file { $data_file_directories:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => Package['cassandra'],
    }

    file { $commitlog_directory:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => Package['cassandra'],
    }

    file { $saved_caches_directory:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => Package['cassandra'],
    }

    file { '/etc/cassandra/cassandra-env.sh':
        content => template("${module_name}/cassandra-env.sh.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    file { '/etc/cassandra/cassandra.yaml':
        content => template("${module_name}/cassandra.yaml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    file { '/etc/cassandra/cqlshrc':
        content => template("${module_name}/cqlshrc.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => Package['cassandra'],
    }

    if $application_username != undef {
        file { '/etc/cassandra/adduser.cql':
            content => template("${module_name}/adduser.cql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            require => Package['cassandra'],
        }
    }

    if ($tls_cluster_name) {
        file { '/etc/cassandra/tls':
            ensure  => directory,
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
            require => Package['cassandra'],
        }

        file { '/etc/cassandra/tls/server.key':
            content => secret("cassandra/${tls_cluster_name}/${hostname}/${hostname}.kst"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
            require => File['/etc/cassandra/tls'],
        }

        file { '/etc/cassandra/tls/server.trust':
            content => secret("cassandra/${tls_cluster_name}/truststore"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
            require => File['/etc/cassandra/tls'],
        }
    }

    file { '/etc/default/cassandra':
        content => template("${module_name}/cassandra.default.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    # cassandra-rackdc.properties is used by the
    # GossipingPropertyFileSnitch.  Only render
    # it if we are using that endpoint_snitch.
    $rackdc_properties_ensure = $endpoint_snitch ? {
        'GossipingPropertyFileSnitch' => file,
        default                       => 'absent',
    }
    file { '/etc/cassandra/cassandra-rackdc.properties':
        ensure  => $rackdc_properties_ensure,
        content => template("${module_name}/cassandra-rackdc.properties.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => Package['cassandra'],
    }

    # This Puppet module does not support
    # PropertyFileSnitch, which uses these files.
    file { ['/etc/cassandra/cassandra-topology.properties', '/etc/cassandra/cassandra-topology.yaml']:
        ensure => 'absent',
    }

    file { '/etc/cassandra.in.sh':
        ensure  => present,
        source  => "puppet:///modules/${module_name}/cassandra.in.sh",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
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

    base::service_unit { 'cassandra':
        ensure        => present,
        template_name => 'cassandra',
        systemd       => true,
        refresh       => false,
        require       => [
            File[$data_file_directories],
            File['/etc/cassandra/cassandra-env.sh'],
            File['/etc/cassandra/cassandra.yaml'],
            File['/etc/cassandra/cassandra-rackdc.properties'],
        ],
    }
}
