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
#   The name of this cassandra instance, it must have a corresponding key in
#   $instances, see below. The name "default" can be used as instance name to
#   obtain cassandra's standard behaviour with a single instance.
#
#   Unless default behaviour (as in Cassandra's Debian package) is wanted, each
#   instance will have its configuration deployed at /etc/cassandra-<TITLE>
#   with data at /srv/cassandra-<TITLE> and a corresponding nodetool
#   binary named nodetool-<TITLE> to be used to access instances individually.
#   Similarly each instance service will be available under
#   "cassandra-<TITLE>".
#
# [*instances*]
#   An hash from instance name to several instance-specific parameters,
#   including:
#     * jmx_port        must be unique per-host
#     * listen_address  address to use for cassandra clients
#     * rpc_address     address to use for cassandra cluster traffic
#
#   Note any other parameter from the "cassandra" class is in scope and
#   will be inherited here and can be used e.g. in templates.
#
#   Default: $::cassandra::instances
#
define cassandra::instance(
    $instances = $::cassandra::instances,
    $max_heap_size = $::cassandra::max_heap_size,
    $heap_new_size = $::cassandra::heap_newsize,
    $jmx_port = undef,
    $listen_address = undef,
    $rpc_address = undef,
    $jmx_exporter_enabled = false,
    $data_directory_base = "/srv/cassandra-${title}",

    $config_directory = "/etc/cassandra-${title}",
    $service_name = "cassandra-${title}",
    $tls_hostname = "${::hostname}-${title}",
    $pid_file = "/var/run/cassandra/cassandra-${title}.pid",
    $instance_id = "${::hostname}-${title}",
    $data_file_directories = ['data'],
    $commitlog_directory = "/srv/cassandra-${title}/commitlog",
    $hints_directory = "/srv/cassandra-${title}/data/hints",
    $heapdump_directory = "/srv/cassandra-${title}/",
    $saved_caches_directory = "/srv/cassandra-${title}/saved_caches",
) {
    $instance_name = $title

    # Default jmx port; only works with 1-letter instnaces
    $default_jmx_port     = 7189 + inline_template("<%= @title.ord - 'a'.ord %>")

    # Relevant values, choosing convention over configuration
    $actual_jmx_port    = pick($jmx_port, $default_jmx_port)
    $actual_rpc_address = pick($rpc_address, $listen_address)
    # Add the IP address if not present
    if $actual_rpc_address != $facts['ipaddress'] {
        interface::alias { "cassandra-${instance_name}":
            ipv4      => $actual_rpc_address,
        }
    }

    $tls_cluster_name       = $::cassandra::tls_cluster_name
    $application_username   = $::cassandra::application_username
    $native_transport_port  = $::cassandra::native_transport_port
    $target_version         = $::cassandra::target_version

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

    file { [$data_file_directories,
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
        ensure  => present,
        source  => "puppet:///modules/${module_name}/logback-tools.xml",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
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
            ensure  => present,
            source  => "puppet:///modules/${module_name}/hotspot_compiler",
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0444',
        }

        file { "${config_directory}/commitlog_archiving.properties":
            ensure  => present,
            source  => "puppet:///modules/${module_name}/commitlog_archiving.properties",
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0444',
        }
    }

    systemd::service { $service_name:
        ensure  => present,
        content => systemd_template('cassandra'),
        require => [
            File[$data_file_directories],
            File["${config_directory}/cassandra-env.sh"],
            File["${config_directory}/cassandra.yaml"],
            File["${config_directory}/cassandra-rackdc.properties"],
        ],
    }
}
