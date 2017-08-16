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
#
# [*title*]
#   The name of this cassandra instance. The name "default" can be used as
#   instance name to obtain cassandra's standard behaviour with a single
#   instance.
#
define cassandra::instance(
    # the following parameters are injected by the main cassandra class
    $cluster_name,
    $memory_allocator,
    $listen_address,
    $tls_cluster_name,
    $application_username,
    $application_password,
    $native_transport_port,
    $target_version,
    $seeds,
    $dc,
    $rack,
    $additional_jvm_opts,
    $extra_classpath,
    $logstash_host,
    $logstash_port,
    $start_rpc,

    # the following parameters need specific default values for single instance
    $config_directory       = "/etc/cassandra-${title}",
    $service_name           = "cassandra-${title}",
    $tls_hostname           = "${::hostname}-${title}",
    $pid_file               = "/var/run/cassandra/cassandra-${title}.pid",
    $instance_id            = "${::hostname}-${title}",
    $jmx_port               = undef,
    $data_directory_base    = "/srv/cassandra-${title}",
    $data_directories       = ['data'],
    $data_file_directories  = undef,
    $commitlog_directory    = "/srv/cassandra-${title}/commitlog",
    $hints_directory        = "/srv/cassandra-${title}/data/hints",
    $heapdump_directory     = "/srv/cassandra-${title}",
    $saved_caches_directory = "/srv/cassandra-${title}/saved_caches",

    # the following parameters have defaults that are sane both for single-
    # and multi-instances
    $jmx_exporter_enabled = false,
    $num_tokens                       = 256,
    $authenticator                    = true,
    $authorizor                       = true,
    $permissions_validity_in_ms       = 2000,
    $disk_failure_policy              = 'stop',
    $row_cache_size_in_mb             = 200,
    $concurrent_reads                 = 32,
    $concurrent_writes                = 32,
    $concurrent_counter_writes        = 32,
    $trickle_fsync                    = true,
    $trickle_fsync_interval_in_kb     = 30240,
    $storage_port                     = 7000,
    $broadcast_address                = undef,
    $start_native_transport           = true,
    $rpc_address                      = undef,
    $rpc_port                         = 9160,
    $rpc_server_type                  = 'sync',
    $incremental_backups              = false,
    $snapshot_before_compaction       = false,
    $auto_snapshot                    = true,
    $compaction_throughput_mb_per_sec = 16,
    $concurrent_compactors            = 1,
    $streaming_socket_timeout_in_ms   = 0,
    $endpoint_snitch                  = 'GossipingPropertyFileSnitch',
    $internode_compression            = 'all',
    $max_heap_size                    = undef,
    $heap_newsize                     = undef,
    $additional_jvm_opts              = [],
    $key_cache_size_in_mb             = 400,
    $internode_encryption             = none,
    $client_encryption_enabled        = false,
    $super_username                   = 'cassandra',
    $super_password                   = 'cassandra',
    $auto_bootstrap                   = true,
) {
    validate_absolute_path($commitlog_directory)
    validate_absolute_path($hints_directory)
    validate_absolute_path($saved_caches_directory)
    validate_absolute_path($data_directory_base)

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

    validate_string($logstash_host)
    # lint:ignore:only_variable_string
    validate_re("${logstash_port}", '^[0-9]+$')
    # lint:endignore

    if (!is_integer($trickle_fsync_interval_in_kb)) {
        fail('trickle_fsync_interval_in_kb must be number')
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

    $actual_data_file_directories = $data_file_directories ? {
        undef => prefix($data_directories, "${data_directory_base}/"),
        default => $data_file_directories,
    }

    if (empty($actual_data_file_directories)) {
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

    $instance_name = $title

    # Default jmx port; only works with 1-letter instnaces
    $default_jmx_port     = 7189 + inline_template("<%= @title.ord - 'a'.ord %>")

    # Relevant values, choosing convention over configuration
    $actual_jmx_port    = pick($jmx_port, $default_jmx_port)
    if (!is_integer($actual_jmx_port)) {
        fail('jmx_port must be a port number between 1 and 65535')
    }

    $actual_rpc_address = pick($rpc_address, $listen_address)
    # Add the IP address if not present
    if $actual_rpc_address != $facts['ipaddress'] {
        interface::alias { "cassandra-${instance_name}":
            ipv4      => $actual_rpc_address,
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

    file { [$actual_data_file_directories,
            $commitlog_directory,
            $saved_caches_directory]:
        ensure  => directory,
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0750',
        require => File[$data_directory_base],
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
        source  => "puppet:///modules/${module_name}/prometheus_jmx_exporter.yaml",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0400',
        require => Package['cassandra'],
    }

    if $application_username != undef {
        file { "${config_directory}/adduser.cql":
            content => template("${module_name}/adduser.cql.erb"),
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

    if ($target_version == '3.x') {
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
            File[$actual_data_file_directories],
            File["${config_directory}/cassandra-env.sh"],
            File["${config_directory}/cassandra.yaml"],
            File["${config_directory}/cassandra-rackdc.properties"],
        ],
    }
}
