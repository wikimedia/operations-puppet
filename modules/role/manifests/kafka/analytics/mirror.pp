# == Class role::kafka::analytics::mirror
# Defines Kafka MirrorMaker instances to mirror
# all other Kafka cluster data into the analytics Kafka Cluster
#
# In production, the only other Kafka clusters
# (as of August 2016) are main-eqiad and main-codfw.
# Those clusters mirror prefixed topics to each other,
# in a 'master <-> master' (not really) setup.
# Thus, main-eqiad will have all the topics for
# itself and main-codfw.  It is sufficient
# to just mirror all topics from main-eqiad into
# analytics-eqiad.
#
# It is safe to include this class on multiple hosts.
# Each host it is included on will just fire
# up a new MirrorMaker consumer that will be auto balanced
# by Kafka.
#
class role::kafka::analytics::mirror {
    # For safety, only allow this class to be included in eqiad.
    if $::site != 'eqiad' {
        fail('role::kafka::analytics::mirror must only be used in eqiad')
    }

    $source_config            = kafka_config('main')
    $source_cluster_name      = $source_config['name']

    $destination_config       = kafka_config('analytics')


    # TODO: fix this hiera lookup when this is moved into profiles
    $kafka_message_max_bytes = hiera('kafka_message_max_bytes', 1048576)
    # The requests not only contain the message but also a small metadata overhead.
    # So if we want to produce a kafka_message_max_bytes payload the max request size should be a bit higher.
    # The 48564 value isn't arbitrary - it's the difference between default message.max.size and default max.request.size
    $producer_request_max_size = $kafka_message_max_bytes + 48564
    $producer_properties = {
        'max.request.size' => $producer_request_max_size,
    }

    ::confluent::kafka::mirror::instance { "${source_cluster_name}_to_analytics":
        source_zookeeper_url      => $source_config['zookeeper']['url'],
        destination_brokers       => split($destination_config['brokers']['string'], ','),
        jmx_port                  => 9997,
        num_streams               => 2,
        offset_commit_interval_ms => 5000,
        # 2016-10 - MirrorMaker has been dying with errors about
        # batch expirations.  I think is because kafka1018 has been
        # down (due to a bad disk) for a while, and is really busy
        # resyncing.  acks=all makes a batch wait for all brokers
        # in the ISR to ack, and if a single broker takes a while,
        # an exception is thrown.  This isn't the best solution,
        # we should be able to use acks=all, but for analytics purposes
        # this should be acceptable (for now).
        acks                      => 1,
        producer_properties       => $producer_properties,
    }
}
