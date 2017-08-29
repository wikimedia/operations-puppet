# == Class role::kafka::main::mirror
# Defines Kafka MirrorMaker instances to Mirror
# datacenter prefixed topics from other datacenter main Kafka Clusters
# into this datacenter's main Kafka Cluster.
#
# NOTE: This class cannot be used in labs.
#
# In production, this is used to mirror
# 'eqiad*' topics from main-eqiad into main-codfw, and
# 'codfw*' topics from main-codfw into main-eqiad.
#
# The MirrorMaker instances should run on the destination
# hosts.  That is, the instances that produce
# to main-eqiad and consume from main-codfw run
# on the main-eqiad brokers, and vice versa, as it is
# wiser to colocate the instance with the destination cluster.
#
# It is safe to include this class on multiple hosts in either
# codfw or eqiad.  Each host it is included on will just fire
# up a new MirrorMaker consumer that will be auto balanced
# by Kafka.
#
class role::kafka::main::mirror {
    if $::realm == 'labs' {
        fail('role::kafka::main::mirror cannot be used in labs.')
    }
    if ($::site != 'eqiad' and $::site != 'codfw') {
        fail('role::kafka::main::mirror can only be used in eqiad and codfw')
    }

    # If we are in eqiad, then the source cluster will be main-codfw.
    # If we are in codfw, then the source cluster will be main-eqiad
    $source_site = $::site ? {
        'eqiad' => 'codfw',
        'codfw' => 'eqiad'
    }
    $source_config      = kafka_config('main', $source_site)

    # The local site's Kafka cluster will be the destination cluster.
    $destination_config = kafka_config('main')

    # TODO: fix this hiera lookup when this is moved into profiles
    $kafka_message_max_bytes = hiera('kafka_message_max_bytes', 1048576)
    # The requests not only contain the message but also a small metadata overhead.
    # So if we want to produce a kafka_message_max_bytes payload the max request size should be a bit higher.
    # The 48564 value isn't arbitrary - it's the difference between default message.max.size and default max.request.size
    $producer_request_max_size = $kafka_message_max_bytes + 48564
    $producer_proeprties = {
        'max.request.size' => $producer_request_max_size,
    }


    ::confluent::kafka::mirror::instance { "main-${source_site}_to_main-${::site}":
        source_zookeeper_url      => $source_config['zookeeper']['url'],
        destination_brokers       => split($destination_config['brokers']['string'], ','),
        # Only mirror topics from the source that are prefixed with
        # $source_site[\._].
        whitelist                 => "^${source_site}[\\._].+",
        jmx_port                  => 9997,
        num_streams               => 2,
        offset_commit_interval_ms => 5000,
        producer_properites       => $producer_proeprties,
    }
}
