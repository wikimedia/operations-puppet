# == Define: cassandra::instance
#
# Installs and configures a Cassandra server instance
#
# === Usage
# cassandra::instance { 'instance-name':
#     instances => ...
# }
#
# === Parameters
# See cassandra class for parameters already defined there.
#
# [*title*]
#   The name of this cassandra instance. The name "default" can be used as
#   instance name to obtain cassandra's standard behaviour with a single
#   instance.
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
# [*saved_caches_directory*]
#   Directory where Cassandra should store saved caches.
#   Default: /var/lib/cassandra/saved_caches
#
# [*users*]
#   Users to enable on the instance - grants must exist in
#   templates/users
#   Default: []
#
# [*cassandra_passwords*]
#  A mapping of user->passwords from secrets
#  Default: undef
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
# [*broadcast_address*]
#   IP address to broadcast to other Cassandra nodes.  Default: undef (uses $listen _address)
#
# [*start_native_transport*]
#   Whether to start the native transport server.  Default: true
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
# [*jmx_port*]
#   Port to listen for JMX queries.
#   Default: 7199
#
# [*key_cache_size_in_mb*]
#   Maximum size of the key cache in memory.
#   Default: empty (aka "auto" (min(5% of heap (in MB), 100MB)))
#
# [*internode_encryption*]
#   What level of inter node encryption to enable
#   Default: none
#
# [*client_encryption_enabled*]
#   Enable client-side encryption
#   Default: false
#
# [*client_encryption_optional*]
#   Controls whether client encryption is optional (only relevant when encryption is enabled,
#   see: client_encryption_enabled)
#   Default: false
#
# [*auto_bootstrap*]
#   Control whether new nodes joining the cluster will get data they own.
#   Default: true
#
define cassandra::instance(
    # the following parameters are injected by the main cassandra class
    Optional[String]                 $cluster_name          = undef,
    Optional[String]                 $memory_allocator      = undef,
    Optional[Stdlib::IP::Address]    $listen_address        = undef,
    Optional[String]                 $tls_cluster_name      = undef,
    Optional[String]                 $default_applications  = undef,
    Optional[Stdlib::Port]           $native_transport_port = undef,
    Optional[String]                 $target_version        = undef,
    Optional[Array[Stdlib::Host, 1]] $seeds                 = undef,
    Optional[String]                 $dc                    = undef,
    Optional[String]                 $rack                  = undef,
    Optional[Array[String]]          $additional_jvm_opts   = undef,
    Optional[Array[String]]          $extra_classpath       = undef,
    Optional[Stdlib::Host]           $logstash_host         = undef,
    Optional[Stdlib::Port]           $logstash_port         = undef,
    Optional[Boolean]                $start_rpc             = undef,
    Optional[String]                 $super_username        = undef,
    Optional[String]                 $super_password        = undef,

    # the following parameters need specific default values for single instance
    Stdlib::Unixpath        $config_directory       = "/etc/cassandra-${title}",
    String                  $service_name           = "cassandra-${title}",
    String                  $tls_hostname           = "${::hostname}-${title}",
    Stdlib::Unixpath        $pid_file               = "/var/run/cassandra/cassandra-${title}.pid",
    String                  $instance_id            = "${::hostname}-${title}",
    Optional[Stdlib::Port]  $jmx_port               = undef,
    Stdlib::Unixpath        $data_directory_base    = "/srv/cassandra-${title}",
    Array[String]           $data_directories       = ['data'],
    Array[Stdlib::Unixpath] $data_file_directories  = [],
    Stdlib::Unixpath        $commitlog_directory    = "/srv/cassandra-${title}/commitlog",
    Stdlib::Unixpath        $hints_directory        = "/srv/cassandra-${title}/data/hints",
    Stdlib::Unixpath        $heapdump_directory     = "/srv/cassandra-${title}",
    Stdlib::Unixpath        $saved_caches_directory = "/srv/cassandra-${title}/saved_caches",
    Array[String]           $users                  = [],
    Hash[String, String]    $cassandra_passwords    = {},

    # the following parameters have defaults that are sane both for single-
    # and multi-instances
    Integer                               $num_tokens                       = 256,
    Boolean                               $authenticator                    = true,
    Boolean                               $authorizor                       = true,
    Integer                               $permissions_validity_in_ms       = 2000,
    Enum['stop', 'best_effort', 'ignore'] $disk_failure_policy              = 'stop',
    Integer                               $row_cache_size_in_mb             = 200,
    Integer                               $concurrent_reads                 = 32,
    Integer                               $concurrent_writes                = 32,
    Integer                               $concurrent_counter_writes        = 32,
    Boolean                               $trickle_fsync                    = true,
    Integer                               $trickle_fsync_interval_in_kb     = 30240,
    Stdlib::Port                          $storage_port                     = 7000,
    Optional[Stdlib::IP::Address]         $broadcast_address                = undef,
    Boolean                               $start_native_transport           = true,
    Optional[Stdlib::IP::Address]         $rpc_address                      = undef,
    Stdlib::Port                          $rpc_port                         = 9160,
    Enum['hsha', 'sync', 'async']         $rpc_server_type                  = 'sync',
    Boolean                               $incremental_backups              = false,
    Boolean                               $snapshot_before_compaction       = false,
    Boolean                               $auto_snapshot                    = true,
    Integer                               $compaction_throughput_mb_per_sec = 16,
    Integer                               $concurrent_compactors            = 1,
    Integer                               $streaming_socket_timeout_in_ms   = 0,
    String                                $endpoint_snitch                  = 'GossipingPropertyFileSnitch',
    Enum['all', 'dc', 'none']             $internode_compression            = 'all',
    Optional[String]                      $max_heap_size                    = undef,
    Optional[String]                      $heap_newsize                     = undef,
    Integer                               $key_cache_size_in_mb             = 400,
    Enum['all','dc', 'none']              $internode_encryption             = 'none',
    Boolean                               $client_encryption_enabled        = false,
    Boolean                               $client_encryption_optional       = false,
    Boolean                               $auto_bootstrap                   = true,
    Boolean                               $monitor_enabled                  = true,
) {

    $instance_data_file_directories = $data_file_directories.empty? {
        true => prefix($data_directories, "${data_directory_base}/"),
        default => $data_file_directories,
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

    $instance_name = $title

    # Default jmx port; only works with 1-letter instnaces
    $default_jmx_port     = 7189 + Integer(inline_template("<%= @title.ord - 'a'.ord %>"))

    # Relevant values, choosing convention over configuration
    $instance_jmx_port    = pick($jmx_port, $default_jmx_port)

    $instance_rpc_address = pick($rpc_address, $listen_address)

    # Add the IP address if not present
    if $instance_rpc_address != $facts['ipaddress'] {
        interface::alias { "cassandra-${instance_name}":
            ipv4      => $instance_rpc_address,
        }
    }

    file { $config_directory:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['cassandra'],
    }

    file { $data_directory_base:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => Package['cassandra'],
    }

    # Storage directories are an array of arbitrary, fully-qualified paths;
    # Since we cannot guarantee a common base path, ensure will not work.
    flatten([$instance_data_file_directories, $commitlog_directory, $saved_caches_directory, $hints_directory]).each | $data_dir | {
        exec { "install-${data_dir}":
            command => "install -o cassandra -g cassandra -m 750 -d ${data_dir}",
            path    => '/usr/bin/:/bin/',
            before  => Systemd::Service[$service_name],
            creates => $data_dir,
        }
    }

    file { "${config_directory}/cassandra-env.sh":
        ensure  => present,
        content => template("${module_name}/cassandra-env.sh-${target_version}.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    file { "${config_directory}/cassandra.yaml":
        ensure  => present,
        content => template("${module_name}/cassandra.yaml-${target_version}.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    file { "${config_directory}/cassandra-rackdc.properties":
        ensure  => present,
        content => template("${module_name}/cassandra-rackdc.properties.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    file { "${config_directory}/logback.xml":
        ensure  => present,
        content => template("${module_name}/logback.xml-${target_version}.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    file { "${config_directory}/logback-tools.xml":
        ensure => present,
        source => "puppet:///modules/${module_name}/logback-tools.xml",
        owner  => 'cassandra',
        group  => 'cassandra',
        mode   => '0444',
    }

    file { "${config_directory}/cqlshrc":
        content => template("${module_name}/cqlshrc.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => Package['cassandra'],
    }

    file { "${config_directory}/prometheus_jmx_exporter.yaml":
        ensure  => present,
        source  => "puppet:///modules/${module_name}/prometheus_jmx_exporter-${target_version}.yaml",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0400',
        links   => follow,
        require => Package['cassandra'],
    }

    ensure_packages(['prometheus-jmx-exporter'])

    $prometheus_target = $instance_name ? {
        'default' => $::hostname,
        default   => "${::hostname}-${instance_name}",
    }
    prometheus::jmx_exporter_instance { $prometheus_target:
        hostname => $prometheus_target,
        port     => 7800,
    }

    $users.each |String $username| {
        $application_password = $cassandra_passwords[$username]
        file { "${config_directory}/user_${username}.cql":
            content => template("${module_name}/users/${username}.cql.erb"),
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            require => Package['cassandra'],
        }
    }

    if ($tls_cluster_name) {
        file { "${config_directory}/tls":
            ensure  => directory,
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
            require => Package['cassandra'],
        }

        file { "${config_directory}/tls/server.key":
            content   => secret("cassandra/${tls_cluster_name}/${tls_hostname}/${tls_hostname}.kst"),
            owner     => 'cassandra',
            group     => 'cassandra',
            mode      => '0400',
            show_diff => false,
        }

        file { "${config_directory}/tls/server.trust":
            content => secret("cassandra/${tls_cluster_name}/truststore"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
        }

        file { "${config_directory}/tls/rootCa.crt":
            content => secret("cassandra/${tls_cluster_name}/rootCa.crt"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
        }
    }

    if $instance_name != 'default' {
        file { "/usr/local/bin/nodetool-${instance_name}":
            ensure  => link,
            target  => '/usr/local/bin/nodetool-instance',
            require => File['/usr/local/bin/nodetool-instance'],
        }
    }

    file { "/etc/cassandra-instances.d/${tls_hostname}.yaml":
        content => template("${module_name}/instance.yaml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
    }

    if ($target_version in ['3.x', 'dev']) {
        file { "${config_directory}/jvm.options":
            ensure  => present,
            content => template("${module_name}/jvm.options-${target_version}.erb"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0444',
        }

        file { "${config_directory}/hotspot_compiler":
            ensure => present,
            source => "puppet:///modules/${module_name}/hotspot_compiler",
            owner  => 'cassandra',
            group  => 'cassandra',
            mode   => '0444',
        }

        file { "${config_directory}/commitlog_archiving.properties":
            ensure => present,
            source => "puppet:///modules/${module_name}/commitlog_archiving.properties",
            owner  => 'cassandra',
            group  => 'cassandra',
            mode   => '0444',
        }
    }

    systemd::service { $service_name:
        ensure  => present,
        content => systemd_template('cassandra'),
        require => [
            File["${config_directory}/cassandra-env.sh"],
            File["${config_directory}/cassandra.yaml"],
            File["${config_directory}/cassandra-rackdc.properties"],
        ],
    }
}
