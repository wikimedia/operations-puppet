# == Class role::kafka::jumbo::mirror
# Defines Kafka MirrorMaker instances to mirror
# main Kafka cluster data into the jumbo Kafka Cluster
#
# In production, the only other Kafka clusters
# (as of October 2017) are main-eqiad and main-codfw.
# Those clusters mirror prefixed topics to each other,
# in a 'master <-> master' (not really) setup.
# Thus, main-eqiad will have all the topics for
# itself and main-codfw.  It is sufficient
# to just mirror all topics from main-eqiad into
# jumbo-eqiad.
#
# It is safe to include this class on multiple hosts.
# Each host it is included on will just fire
# up a new MirrorMaker consumer that will be auto balanced
# by Kafka.
#
# NOTE:  We would much rather just include profile::kafka::mirror here,
# rather than manually configuring the mirror maker instance in this
# role class.  However, since profile::kafka::mirror is for configuring
# a 0.11 MirrorMaker instance, we can't yet use it, since
# 0.11 Kafka clients are incompatible with 0.9 Brokers (which is what
# main Kafka clusters use).  Once main Kafka clusters are upgraded to 0.9,
# we can use profile::kafka::mirror instead.
#
class role::kafka::jumbo::mirror {
    # For safety, only allow this class to be included in eqiad.
    if $::site != 'eqiad' {
        fail('role::kafka::jumbo::mirror must only be used in eqiad')
    }

    $source_config            = kafka_config('main')
    $source_cluster_name      = $source_config['name']

    $destination_config       = kafka_config('jumbo')
    $destination_cluster_name = $destination_config['name']

    # TODO: fix this hiera lookup when this is moved into profiles
    $kafka_message_max_bytes = hiera('kafka_message_max_bytes', 1048576)
    # The requests not only contain the message but also a small metadata overhead.
    # So if we want to produce a kafka_message_max_bytes payload the max request size should be a bit higher.
    # The 48564 value isn't arbitrary - it's the difference between default message.max.size and default max.request.size
    $producer_request_max_size = $kafka_message_max_bytes + 48564
    $producer_properties = {
        'max.request.size' => $producer_request_max_size,
    }

    $consumer_properties = {
        # RoundRobin results in more balanced consumer assignment when dealing
        # with many single partition topics.
        'partition.assignment.strategy' => 'org.apache.kafka.clients.consumer.RoundRobinAssignor',
        'max.partition.fetch.bytes'     => $producer_request_max_size
    }

    ::confluent::kafka::mirror::instance { "${source_cluster_name}_to_${destination_cluster_name}":
        new_consumer              => true,
        source_brokers            => split($source_config['brokers']['string'], ','),
        destination_brokers       => split($destination_config['brokers']['string'], ','),
        # Avoid conflict on port 9997 with main -> analytics mirror maker
        jmx_port                  => 9996,
        num_streams               => 2,
        offset_commit_interval_ms => 5000,
        # Jumbo's MirrorMaker producer is being incredibly flaky.  We think
        # this is likely due to version discrepencies, and hope to have them
        # resolved after we upgrade main Kafka to 1.x.  For now, blacklisting
        # high volume job topics from replication seems to help.  We
        # haven't needed these replicated out of main for any purpose yet, so
        # this should be fine for now.  See T189464.
        # blacklist doesn't work with new_consumer, use whitelist instead.
        # blacklist                 => '.*mediawiki\.job\..*|.*change-prop\..*',
        whitelist                 => '^(?!__).+\.(error|resource_change|mediawiki\.(page|recentchange|revision|user).+)$',
        # Seen OutOfMemoryError in this mirror maker instance, increase heap size.
        heap_opts                 => '-Xmx512M -Xms512M',
        producer_properties       => $producer_properties,
        consumer_properties       => $consumer_properties,
    }

}
