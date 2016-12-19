# == Class: role::graphite::alerts
#
# Install icinga alerts on graphite metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class role::graphite::alerts {

    include ::mediawiki::monitoring::graphite
    include ::graphite::monitoring::graphite

    $kafka_config = kafka_config('analytics')

    # Alerts for EventLogging metrics in Kafka.
    class { '::eventlogging::monitoring::graphite':
        kafka_brokers_graphite_wildcard => $kafka_config['brokers']['graphite']
    }

    swift::monitoring::graphite_alerts { 'eqiad-prod': }
    swift::monitoring::graphite_alerts { 'codfw-prod': }

    # Use graphite's anomaly detection support.
    monitoring::graphite_anomaly { 'kafka-analytics-eqiad-broker-MessagesIn-anomaly':
        description  => 'Kafka Cluster analytics-eqiad Broker Messages In Per Second',
        metric       => 'sumSeries(kafka.cluster.analytics-eqiad.kafka.*.kafka.server.BrokerTopicMetrics-AllTopics.MessagesInPerSec.OneMinuteRate)',
        # check over the 60 data points (an hour?) and:
        # - alert warn if more than 30 are under the confidence band
        # - alert critical if more than 45 are under the confidecne band
        check_window => 60,
        warning      => 30,
        critical     => 45,
        under        => true,
        group        => 'analytics_eqiad',
    }

    # Monitor memcached error rate from MediaWiki. This is commonly a sign of
    # a failing nutcracker instance that can be tracked down via
    # https://logstash.wikimedia.org/#/dashboard/elasticsearch/memcached
    monitoring::graphite_threshold { 'mediawiki-memcached-threshold':
        description => 'MediaWiki memcached error rate',
        metric      => 'transformNull(logstash.rate.mediawiki.memcached.ERROR.sum, 0)',
        # Nominal error rate in production is <150/min
        warning     => 1000,
        critical    => 5000,
        from        => '5min',
        percentage  => 40,
    }

    # Monitor MediaWiki fatals and exceptions.
    monitoring::graphite_threshold { 'mediawiki_error_rate':
        description => 'MediaWiki exceptions and fatals per minute',
        metric      => 'transformNull(sumSeries(logstash.rate.mediawiki.fatal.ERROR.sum, logstash.rate.mediawiki.exception.ERROR.sum), 0)',
        warning     => 25,
        critical    => 50,
        from        => '10min',
        percentage  => 70,
    }

    # Monitor EventBus 4xx and 5xx HTTP response rate.
    monitoring::graphite_threshold { 'eventbus_http_error_rate':
        description => 'EventBus HTTP Error Rate (4xx + 5xx)',
        metric      => 'transformNull(sumSeries(eventbus.counters.eventlogging.service.EventHandler.POST.[45]*.rate))',
        # If > 50% of datapoints over last 10 minutes is over thresholds, then alert.
        warning     => 1,
        critical    => 10,
        from        => '10min',
        percentage  => 50,
    }
}

