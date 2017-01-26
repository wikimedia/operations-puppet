# == Define confluent::kafka::mirror::instance
# Sets up a Kafka MirrorMaker instance and ensures that it is running.
# jmx_port, destination_brokers, and source_zookeeper_url are required
# parameters.
#
# == Parameters
#
# [*source_zookeeper_url*]
#   The URL that the source Kafka cluster users for coordination.
#   The MirrorMaker consumer users this to look up source cluster
#   metadata and start consuming.
#
# [*destination_brokers*]
#   Array of Kafka brokers hosts in your destination cluster.  These brokers
#   will be used for bootstrapping the producers configs and metadata.
#
# [*jmx_port*]
#   Port on which to expose MirrorMaker JMX metrics.
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
#   Java regex matching topics to mirror. You must set either this or
#   $blacklist.  Default: '.*'
#
# [*blacklist*]
#   Java regex matching topics to not mirror.  Default: undef
#   You must set either this or $topic_whitelist
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
# [*monitoring_enabled*]
#   If true, both ::jmxtrans and ::alerts will be defined
#   on this node for this MirrorMaker instance.  Default: true
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
    # Consumer Settings
    $source_zookeeper_url,
    $destination_brokers,
    $jmx_port,

    $consumer_properties          = {},

    # Producer Settings
    $acks                         = 'all',
    $compression_type             = 'snappy',
    $linger_ms                    = 1000,
    $producer_properties          = {},

    $enabled                      = true,

    $whitelist                    = '.*',
    $blacklist                    = undef,

    $num_streams                  = 1,
    $offset_commit_interval_ms    = 10000,
    $heap_opts                    = undef,

    $monitoring_enabled           = true,

    $consumer_properties_template = 'confluent/kafka/mirror/consumer.properties.erb',
    $producer_properties_template = 'confluent/kafka/mirror/producer.properties.erb',
    $default_template             = 'confluent/kafka/mirror/kafka-mirror.default.erb',
    $log4j_properties_template    = 'confluent/kafka/mirror/log4j.properties.erb',
)
{
    require ::confluent::kafka::client

    if (!$whitelist and !$blacklist) or ($whitelist and $blacklist) {
        fail('Must set only one of $whitelist or $blacklist.')
    }

    $mirror_name = $title

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
    base::service_unit{ "kafka-mirror-${mirror_name}":
        ensure        => $service_ensure,
        template_name => 'kafka-mirror',
        systemd       => true,
        refresh       => false,
        require       => [
            File["/etc/kafka/mirror/${mirror_name}/log4j.properties"],
            File["/etc/kafka/mirror/${mirror_name}/consumer.properties"],
            File["/etc/kafka/mirror/${mirror_name}/producer.properties"],
            File["/etc/default/kafka-mirror-${mirror_name}"],
        ],
    }

    if $monitoring_enabled {
        # Include Kafka Mirror Jmxtrans class
        # to send Kafka MirrorMaker metrics to statsd.
        # metrics will look like:
        # kafka.mirror.$mirror_name.kafka-mirror. ...
        $group_prefix = "kafka.mirror.${mirror_name}."
        confluent::kafka::mirror::jmxtrans { $mirror_name:
            group_prefix => $group_prefix,
            statsd       => hiera('statsd', undef),
            jmx_port     => $jmx_port,
            require      => Base::Service_unit["kafka-mirror-${mirror_name}"],
        }

        # Monitor kafka in production
        if $::realm == 'production' {
            confluent::kafka::mirror::alerts { $mirror_name:
                group_prefix => $group_prefix,
            }
        }
    }
}
