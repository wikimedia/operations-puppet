# == Define confluent::kafka::mirror::instance
# Sets up a Kafka MirrorMaker instance and ensures that it is running.
# jmx_port, destination_brokers, and source_zookeeper_url are required
# parameters.
#
# == Parameters
#
# [*source_brokers*]
#   Array of Kafka broker hosts in your source cluster.  These brokers
#   will be used for bootstrapping the consumer configs and metadata.
#
# [*destination_brokers*]
#   Array of Kafka brokers hosts in your destination cluster.  These brokers
#   will be used for bootstrapping the producers configs and metadata.
#
# [*jmx_port*]
#   Port on which to expose MirrorMaker JMX metrics.
#
# [*group_id*]
#   Consumer group.id.  Default: kafka-mirror-$title.
#
# [*consumer_properties*]
#   Other Consumer related properties to set in this MirrorMaker
#   instance's consumer.properties file.
#   See: http://kafka.apache.org/documentation.html#oldconsumerconfigs
#
# [*acks*]
#   Required number of acks for a produce request. Default: all (all replicas)
#
# [*compression_codec*]
#   none, gzip, or snappy.  Default: snappy
#
# [*linger_ms*]
#   Batches will be produced in either every linger_ms, or every batch.size
#   messages, whichever comes first.  Default: 1000.  (Default batch.size is
#   16384)
#
# [*producer_properties*]
#   Other Producer related properites to set in this MirrorMaker
#   instance's producer.properties file.
#   See http://kafka.apache.org/documentation.html#producerconfigs
#
# [*enabled*]
#   If false, kafka mirror-maker service will not be started.  Default: true.
#
# [*whitelist*]
#   Java regex matching topics to mirror.  Default: '.*'
#
# [*num_streams*]
#   Number of consumer threads.  Default: 1
#
# [*offset_commit_interval_ms*]
#    Offset commit interval in ms.  Default: 10000
#
# [*heap_opts*]
#   Heap options to pass to JVM on startup.  Default: undef
#
# [*java_opts*]
#   Extra Java options.  Default: undef
#
# == Usage
#
#   # Mirror the 'main' Kafka cluster
#   # to the 'aggregate' Kafka cluster.
#   confluent::kafka::mirror::instance { 'main_to_aggregate':
#       source_zookeeper_url => 'zk:2181/kafka/main',
#       destination_brokers => ['ka01:9092','ka02:9092'],
#       jmx_port            => 9997,
#
#   }
#   # Mirror the 'secondary' Kafka cluster
#   # to the 'aggregate' Kafka cluster.
#   confluent::kafka::mirror::instance { 'secondary_to_aggregate':
#       source_zookeeper_url => 'zk:2181/kafka/secondary',
#       destination_brokers => ['ka01:9092','ka02:9092'],
#       jmx_port            => 9996,
#   }
#
define confluent::kafka::mirror::instance(
    $destination_brokers,
    $source_brokers,
    $jmx_port,

    $group_id                     = "kafka-mirror-${title}",
    $consumer_properties          = {},

    # Producer Settings
    $acks                         = 'all',
    $compression_type             = 'snappy',
    $linger_ms                    = 1000,
    $producer_properties          = {},

    $enabled                      = true,

    $whitelist                    = '.*',

    $num_streams                  = 1,
    $offset_commit_interval_ms    = 10000,
    $heap_opts                    = undef,
    $java_opts                    = undef,

    $consumer_properties_template = 'confluent/kafka/mirror/consumer.properties.erb',
    $producer_properties_template = 'confluent/kafka/mirror/producer.properties.erb',
    $default_template             = 'confluent/kafka/mirror/kafka-mirror.default.erb',
    $log4j_properties_template    = 'confluent/kafka/mirror/log4j.properties.erb',

)
{
    require ::confluent::kafka::common

    # Install a catch-all systemd service to ease stopping and starting
    # of all MirrorMaker processes on this host.
    if !defined(Systemd::Service['kafka-mirror']) {
        systemd::service { 'kafka-mirror':
            content => systemd_template('kafka-mirror'),
        }
    }

    $mirror_name = $title
    # client.id used in metric names.
    $client_id   = "kafka-mirror-${::hostname}-${mirror_name}"

    # Local variable for rendering in templates.
    $java_home = $::confluent::kafka::common::java_home

    file { "/etc/kafka/mirror/${mirror_name}":
        ensure  => 'directory',
        recurse => true,
        purge   => true,
    }

    # Log to custom log file for this MirrorMaker instance.
    $log_file = "/var/log/kafka/kafka-mirror-${mirror_name}.log"
    file { "/etc/kafka/mirror/${mirror_name}/log4j.properties":
        content => template($log4j_properties_template),
    }

    file { "/etc/kafka/mirror/${mirror_name}/consumer.properties":
        content => template($consumer_properties_template),
    }

    file { "/etc/kafka/mirror/${mirror_name}/producer.properties":
        content => template($producer_properties_template),
    }

    file { "/etc/default/kafka-mirror-${mirror_name}":
        content => template($default_template),
    }

    $service_ensure = $enabled ? {
        false   => 'absent',
        default => 'present',
    }
    # Start the MirrorMaker instance.
    # We don't want to subscribe to the config files here.
    systemd::service { "kafka-mirror-${mirror_name}":
        ensure  => $service_ensure,
        content => systemd_template('kafka-mirror-instance'),
        require => [
            File["/etc/kafka/mirror/${mirror_name}/log4j.properties"],
            File["/etc/kafka/mirror/${mirror_name}/consumer.properties"],
            File["/etc/kafka/mirror/${mirror_name}/producer.properties"],
            File["/etc/default/kafka-mirror-${mirror_name}"],
        ],
    }
}
