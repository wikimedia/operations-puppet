# == Define: cassandra::instance
#
# Installs and configures a Cassandra server instance
#
# === Usage
# class { '::cassandra::instance':
#     title     => "a"
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
#   Unless default behaviour is wanted, each instance will have its
#   configuration deployed at /etc/cassandra-<TITLE> with data at
#   /var/lib/cassandra-<TITLE> and a corresponding nodetool binary named
#   nodetool-<TITLE> to be used to access instances individually. Similarly
#   each instance service will be available under "cassandra-<TITLE>".
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

define cassandra::instance(
    $instances = $::cassandra::instances,
) {
    $instance_name = $title
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

    file { "${config_directory}/logback.xml":
        content => template("${module_name}/logback.xml.erb"),
        owner   => 'cassandra',
        group   => 'cassandra',
        mode    => '0444',
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
