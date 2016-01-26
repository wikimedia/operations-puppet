# == Class: role::graphite::alerts
#
# Install icinga alerts on graphite metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class role::graphite::alerts {
    # Infer Kafka cluster configuration from this class
    include ::role::kafka::analytics::config

    include ::mediawiki::monitoring::graphite
    include ::graphite::monitoring::graphite

    # Alerts for EventLogging metrics in Kafka.
    class { '::eventlogging::monitoring::graphite':
        kafka_brokers_graphite_wildcard =>  $::role::kafka::analytics::config::brokers_graphite_wildcard
    }

    swift::monitoring::graphite_alerts { 'eqiad-prod': }
    swift::monitoring::graphite_alerts { 'codfw-prod': }

    # Use graphite's anomaly detection support.
    monitoring::graphite_anomaly { 'kafka-broker-MessagesIn-anomaly':
        description  => 'Kafka Broker Messages In Per Second',
        metric       => 'sumSeries(kafka.*.kafka.server.BrokerTopicMetrics-AllTopics.MessagesInPerSec.OneMinuteRate)',
        # check over the 60 data points (an hour?) and:
        # - alert warn if more than 30 are under the confidence band
        # - alert critical if more than 45 are under the confidecne band
        check_window => 60,
        warning      => 30,
        critical     => 45,
        under        => true,
        group        => 'analytics',
    }

    # Monitor memcached error rate from MediaWiki. This is commonly a sign of
    # a failing nutcracker instance that can be tracked down via
    # https://logstash.wikimedia.org/#/dashboard/elasticsearch/memcached
    monitoring::graphite_threshold { 'mediawiki-memcached-threshold':
        description => 'MediaWiki memcached error rate',
        metric      => 'logstash.rate.mediawiki.memcached.ERROR.sum',
        # Nominal error rate in production is <150/min
        warning     => 1000,
        critical    => 5000,
        from        => '5min',
        percentage  => 40,
    }

}

