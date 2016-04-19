# == Class confluent::kafka::broker
# Sets up a Kafka Broker and ensures that it is running.
#
# == Parameters:
#
class confluent::kafka::broker(
    $enabled                             = true,
    $brokers                             = {
        "${::fqdn}" => {
            'id'   => 1,
            'port' => 9092,
        },
    },
    $listeners                           = ['PLAINTEXT://:9092'],
    $log_dirs                            = ['/var/spool/kafka'],

    $num_recovery_threads_per_data_dir   = 1,

    $zookeeper_hosts                     = ['localhost:2181'],
    $zookeeper_chroot                    = undef,
    $zookeeper_connection_timeout_ms     = 6000,
    $zookeeper_session_timeout_ms        = 6000,

    $java_home                           = undef,
    $java_opts                           = undef,
    $classpath                           = undef,
    $jmx_port                            = 9999,
    $heap_opts                           = undef,
    $nofiles_ulimit                      = 8192,

    $auto_create_topics_enable           = true, # changed
    $auto_leader_rebalance_enable        = true,

    $num_partitions                      = size($log_dirs),
    $default_replication_factor          = 1,
    $replica_lag_time_max_ms             = undef,
    $num_recovery_threads_per_data_dir   = 1,
    $replica_socket_timeout_ms           = 3000,
    $replica_socket_receive_buffer_bytes = 65536,
    $num_replica_fetchers                = 1,
    $replica_fetch_max_bytes             = 1048576,

    $num_network_threads                 = 3,
    $num_io_threads                      = size($log_dirs),
    $socket_send_buffer_bytes            = 1048576,
    $socket_receive_buffer_bytes         = 1048576,
    $socket_request_max_bytes            = 104857600,

    # TODO: Tune these?
    $log_flush_interval_messages         = 10000,
    $log_flush_interval_ms               = 1000,

    $log_retention_hours                 = 168,     # 1 week
    $log_retention_bytes                 = undef,
    $log_segment_bytes                   = 1073741824, # changed

    $log_retention_check_interval_ms     = 300000,
    $log_cleanup_policy                  = 'delete',

    $offsets_retention_minutes           = 10080,   # 1 week

    # $metrics_properties                  = $kafka::defaults::metrics_properties,
    $log_max_backup_index                = 4,
    $jvm_performance_opts                = undef,

    $server_properties_template          = 'confluent/kafka/server.properties.erb',
    $default_template                    = 'confluent/kafka/kafka.default.erb',
    $log4j_properties_template           = 'confluent/kafka/log4j.properties.erb',
) {
    # confluent::kafka::client installs the kafka package
    # and a handy wrapper script.
    require ::confluent::kafka::client

    # Get this broker's id out of the $kafka::brokers
    # configuration hash.
    $id = $brokers[$::fqdn]['id']

    $default_port = 9092
    # Using a conditional assignment selector with a
    # Hash value results in a puppet syntax error.
    # Using an if/else instead.
    if ($brokers[$::fqdn]['port']) {
        $port = $brokers[$::fqdn]['port']
    }
    else {
        $port = $default_port
    }

    group { 'kafka':
        ensure  => 'present',
        system  => true,
        require => Class['confluent::kafka::client']
    }
    # Kafka system user
    user { 'kafka':
        gid        => 'kafka',
        shell      => '/bin/false',
        home       => '/nonexistent',
        comment    => 'Apache Kafka',
        system     => true,
        managehome => false,
        require    => Group['kafka'],
    }

    # All following config files first require
    # that the Kafka package has been installed.
    File {
        require => Class['confluent::kafka::client'],
    }

    file { '/var/log/kafka':
        ensure  => 'directory',
        owner   => 'kafka',
        group   => 'kafka',
        mode    => '0755',
    }

    # This is the message data directory,
    # not to be confused with the $kafka_log_file,
    # which contains daemon process logs.
    file { $log_dirs:
        ensure  => 'directory',
        owner   => 'kafka',
        group   => 'kafka',
        mode    => '0755',
    }

    # Render out Kafka Broker config files.
    file { '/etc/kafka/server.properties':
        content => template($server_properties_template),
    }

    # log4j configuration for Kafka daemon
    # process logs (this uses $kafka_log_dir).
    file { '/etc/kafka/log4j.properties':
        content => template($log4j_properties_template),
    }

    # Environment variables that are passed to kafka-run-class.
    file { '/etc/default/kafka':
        content => template($default_template),
    }

    # Start the Kafka server.
    # We don't want to subscribe to the config files here.
    # It will be better to manually restart Kafka when
    # the config files changes.
    $kafka_ensure = $enabled ? {
        false   => 'absent',
        default => 'present',
    }

    base::service_unit{ 'kafka':
        ensure  => $kafka_ensure,
        systemd => true,
        refresh => false,
        require => [
            File[$log_dirs],
            File['/etc/kafka/server.properties'],
            File['/etc/kafka/log4j.properties'],
            File['/etc/default/kafka'],
        ],
    }
}
