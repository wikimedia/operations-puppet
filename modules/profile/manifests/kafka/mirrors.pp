# == Class profile::kafka::mirrors
# Sets up and runs MirrorMaker instances declared in profile::kafka::mirrors::instances.
# This uses the confluent::kafka::mirrors to create_resources based on hiera
# definitions.  This has the advantage of being able to set some defaults, e.g.
# kafka_message_max_bytes, while moving declaration of mirrors to hiera config.
# This has the disadvantage of requireing that you manually specify the bootstrap broker lists
# for both the source and destination clusters that each MirrorMaker instance uses in hiera.
#
# TODO:
# - Prometheus monitoring.  Going to be difficult!
# - TLS configuration
#
# == Hiera Usage:
# Each entry in this hash will be used to declare a confluent::kafka::mirror::instance.
# Keys are MirrorMaker instance names, the values are a hash of confluent::kafka::mirror::instance
# define parameters.
#
# profile::kafka::mirrors::instances:
#   clusterA_to_clusterB:  # This is the 'name' of the MirrorMaker instance.
#     source_brokers:
#       - source1.eqiad.wmnet:9092
#       - source2.eqiad.wmnet:9092
#     destination_brokers:
#       - dest1.eqiad.wmnet:9092
#       - dest2.eqiad.wmnet:9092
#     jmx_port: 9997
#     num_streams: 2
#     offset_commit_interval_ms: 5000
#
class profile::kafka::mirrors(
    $instances            = hiera('profile::kafka::mirrors::instances'),
    $statsd               = hiera('statsd'),
    $message_max_bytes    = hiera('kafka_message_max_bytes'),
    # $monitoring_enabled = hiera('profile::kafka::broker::monitoring_enabled'),
) {
    # FOR NOW,
    $monitoring_enabled = false


    # If monitoring is enabled, then include the monitoring profile and set $java_opts
    # for exposing the Prometheus JMX Exporter in the Kafka Broker process.
    if $monitoring_enabled {
        include ::profile::kafka::broker::monitoring
        $java_opts = $::profile::kafka::broker::monitoring::java_opts
    }
    else {
        $java_opts = undef
    }

    # The requests not only contain the message but also a small metadata overhead.
    # So if we want to produce a kafka_message_max_bytes payload the max request size should be a
    # bit higher.
    # The 48564 value isn't arbitrary - it's the difference between default message.max.size and
    # default max.request.size
    $producer_request_max_size = $message_max_bytes + 48564
    $producer_properties = {
        'max.request.size' => $producer_request_max_size,
    }
    $consumer_properties = {
        'max.partition.fetch.bytes' => $producer_request_max_size
    }

    $default_config = {
        producer_properties => $producer_properties,
        consumer_properties => $consumer_properties,
        monitoring_enabled  => $monitoring_enabled,
    }

    class { '::confluent::kafka::mirrors':
        mirrors         => $instances,
        mirror_defaults => $default_config,
    }
}
