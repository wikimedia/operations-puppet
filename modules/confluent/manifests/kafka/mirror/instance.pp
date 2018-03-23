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
#   metadata and start consuming. NOTE: This parameter is deprecated.
#   0.11 does not require zookeeper for consumer.  Use $source_brokers instead.
#   TODO: Remove this parameter once all clusters are upgraded and using newer mirror maker.
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
# [*consumer_properties*]
#   Other Consumer related properties to set in this MirrorMaker
#   instance's consumer.properties file.
#   See: http://kafka.apache.org/documentation.html#oldconsumerconfigs
#
# [*new_conusumer*]
#   If true, the new consumer client will be used, committing offsets
#   to Kafka instead of Zookeeper.  This is the default in later versions.
#   This option is not compatible with $blacklist, and if used, a $whitelist
#   that excludes internal topics (^__.*) must be given as well, at least
#   until MirrorMaker version has been updated.  If you use this, you must
#   specify $source_brokers instead of $source_zookeeper_url.
#   TODO: remove this option after version is updated.
#   Default: false
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
# [*java_opts*]
#   Extra Java options.  Default: undef
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
    $destination_brokers,
    $jmx_port,

    # TODO: make source_brokers required when we remove $source_zookeeper_url after upgrading mirror maker
    $source_brokers               = undef,
    $source_zookeeper_url         = undef,

    $consumer_properties          = {},
    $new_consumer                 = false,

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
    $java_opts                    = undef,

    $monitoring_enabled           = true,

    $consumer_properties_template = 'confluent/kafka/mirror/consumer.properties.erb',
    $producer_properties_template = 'confluent/kafka/mirror/producer.properties.erb',
    $default_template             = 'confluent/kafka/mirror/kafka-mirror.default.erb',
    $log4j_properties_template    = 'confluent/kafka/mirror/log4j.properties.erb',

)
{
    require ::confluent::kafka::common

    if (!$whitelist and !$blacklist) or ($whitelist and $blacklist) {
        fail('Must set only one of $whitelist or $blacklist.')
    }

    # TODO remove new_consumer checks after kafka 0.11+ update.
    if ($new_consumer and $blacklist) {
        fail('Cannot use $new_consumer with $blacklist, specify $whitelist instead.')
    }
    if ($new_consumer and $source_zookeeper_url) {
        fail('Must specify $source_brokers instead of $source_zookeeper_url when using $new_consumer.')
    }

    $mirror_name = $title

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
        content => systemd_template('kafka-mirror'),
        require => [
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
            require      => Systemd::Service["kafka-mirror-${mirror_name}"],
        }

        # Monitor kafka in production
        if $::realm == 'production' {
            confluent::kafka::mirror::alerts { $mirror_name:
                group_prefix => $group_prefix,
            }
        }
    }
}
