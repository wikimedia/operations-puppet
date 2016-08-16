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
    # If we are in eqiad, then the source cluster will be main-codfw.
    # If we are in codfw, then the source cluster will be main-eqiad
    $source_site = $::site ? {
        'eqiad' => 'codfw',
        'codfw' => 'eqiad'
    }
    $sources = hiera('kafka_mirror_sources', {$source_site => ['main']})
    $destination = hiera('kafka_mirror_destination', ['main', $::site]})

    class { '::confluent::kafka::mirrors':
        mirrors         => kafka_mirror_resources($sources, $destination)
        mirror_defaults => {
            jmx_port                  => 9997,
            num_streams               => 2,
            offset_commit_interval_ms => 5000,
        }
    }
}
