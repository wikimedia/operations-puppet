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
#     * rpc_interface   if specified, add rpc_address to this interface
#
#   Note any other parameter from the "cassandra" class is in scope and
#   will be inherited here and can be used e.g. in templates.
#
#   Default: $::cassandra::instances

define cassandra::instance(
    $instances = $::cassandra::instances,
) {
    $instance_name = $title
    if ! has_key($instances, $instance_name) {
        fail("instance ${instance_name} not found in ${instances}")
    }

    $this_instance  = $instances[$instance_name]
    $jmx_port       = $this_instance['jmx_port']
    $listen_address = $this_instance['listen_address']
    $rpc_address    = $this_instance['rpc_address']
    $rpc_interface  = $this_instance['rpc_interface']
    if $rpc_interface {
        interface::ip { "cassandra-${instance_name}_rpc_${rpc_interface}":
            interface => $rpc_interface,
            address   => $rpc_address,
            prefixlen => '32'
        }
    }

    if $instance_name == 'default' {
        $data_directory_base = '/var/lib/cassandra'
        $config_directory    = '/etc/cassandra'
        $service_name        = 'cassandra'
        $tls_hostname        = $::hostname
        $pid_file            = '/var/run/cassandra/cassandra.pid'
        $instance_id         = $::hostname
        $data_file_directories  = $this_instance['data_file_directories']
        $commitlog_directory    = $this_instance['commitlog_directory']
        $heapdump_directory     = $this_instance['heapdump_directory']
        $saved_caches_directory = $this_instance['saved_caches_directory']
    } else {
        $data_directory_base = "/srv/cassandra-${instance_name}"
        $config_directory    = "/etc/cassandra-${instance_name}"
        $service_name        = "cassandra-${instance_name}"
        $tls_hostname        = "${::hostname}-${::instance_name}"
        $pid_file            = "/var/run/cassandra/cassandra-${instance_name}.pid"
        $instance_id         = "${::hostname}-${::instance_name}"
        $data_file_directories  = ["${data_directory_base}/data"]
        $commitlog_directory    = "${data_directory_base}/commitlog"
        $heapdump_directory     = $data_directory_base
        $saved_caches_directory = "${data_directory_base}/saved_caches"
    }

    $tls_cluster_name       = $::cassandra::tls_cluster_name
    $application_username   = $::cassandra::application_username

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
        content => template("${module_name}/cassandra-env.sh.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => File[$config_directory],
    }

    file { "${config_directory}/cassandra.yaml":
        ensure  => present,
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

    file { "${config_directory}/logback.xml":
        ensure  => present,
        content => template("${module_name}/logback.xml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => File[$config_directory],
    }

    file { "${config_directory}/logback-tools.xml":
        ensure  => present,
        source  => "puppet:///modules/${module_name}/logback-tools.xml",
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
        require => File[$config_directory],
    }

    file { "${config_directory}/cqlshrc":
        content => template("${module_name}/cqlshrc.erb"),
        owner   => 'root',
        group   => 'root',
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
            content => secret("cassandra/${tls_cluster_name}/${tls_hostname}/${tls_hostname}.kst"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
            require => File["${config_directory}/tls"],
        }

        file { "${config_directory}/tls/server.trust":
            content => secret("cassandra/${tls_cluster_name}/truststore"),
            owner   => 'cassandra',
            group   => 'cassandra',
            mode    => '0400',
            require => File["${config_directory}/tls"],
        }
    }

    if $instance_name != 'default' {
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

    nrpe::monitor_systemd_unit_state { $service_name:
        require => Service[$service_name],
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { "${service_name}-cql":
        description   => "${service_name} CQL ${listen_address}:9042",
        check_command => "check_tcp_ip!${listen_address}!9042",
        contact_group => 'admins,team-services',
    }
}
