# == Class role::kafka::analytics::mirror
# Mirrors Kafka topics to the Analytics Kafka cluster.
# For now, this just mirrors from main-eqiad to analytics-eqiad.
#
class role::kafka::analytics::mirror {
    include role::kafka::analytics::config
    include role::kafka::main::config

    require_package('openjdk-7-jdk')

    $mirror_name = 'analytics-eqiad'
    kafka::mirror::consumer { 'main-eqiad':
        mirror_name   => 'analytics-eqiad',
        zookeeper_url => $role::kafka::main::config::zookeeper_url,
    }
    kafka::mirror { $mirror_name:
        destination_brokers    => $role::kafka::analytics::config::brokers_string,
        # Only mirror mediawiki.* topics for now.
        whitelist              => 'mediawiki\..+',
        queue_buffering_max_ms => 1000,
        jmx_port               => 9998,
    }

    # Include Kafka Mirror Jmxtrans class
    # to send Kafka MirrorMaker metrics to statsd.
    # metrics will look like:
    # kafka.mirror.analytics-eqiad.kafka-mirror. ...
    $group_prefix = "kafka.mirror.${mirror_name}."
    kafka::mirror::jmxtrans { 'analytics-eqiad':
        statsd   => hiera('statsd'),
        jmx_port => 9998,
        require  => Kafka::Mirror[$mirror_name]
    }

    # Monitor kafka in production
    if $::realm == 'production' {
        kafka::mirror::monitoring { $mirror_name:
            group_prefix        => $group_prefix,
            nagios_servicegroup => "analytics_${::site}",
        }
    }
}
