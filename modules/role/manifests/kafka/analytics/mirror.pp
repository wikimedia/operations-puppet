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

    ::confluent::kafka::mirror::instance { "${source_cluster_name}_to_analytics":
        source_zookeeper_url      => $source_config['zookeeper']['url'],
        destination_brokers       => split($destination_config['brokers']['string'], ','),
        jmx_port                  => 9997,
        num_streams               => 2,
        offset_commit_interval_ms => 5000,
    }
}
