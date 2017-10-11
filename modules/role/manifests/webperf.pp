# == Class: role::webperf
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf {

    include ::standard
    include ::profile::base::firewall

    $statsd = hiera('statsd')
    $statsd_parts = split($statsd, ':')
    $statsd_host = $statsd_parts[0]
    $statsd_port = $statsd_parts[1]

    # Use brokers from this Kafka cluster to consume metrics.
    $kafka_config  = kafka_config('analytics')
    $kafka_brokers = $kafka_config['brokers']['string']

    # Consume statsd metrics from Kafka and emit them to statsd.
    class { '::webperf::statsv':
        kafka_brokers => $kafka_brokers,
        statsd        => $statsd,
    }

    # Aggregate client-side latency measurements collected via the
    # NavigationTiming MediaWiki extension and send them to Graphite.
    # See <https://www.mediawiki.org/wiki/Extension:NavigationTiming>
    class { '::webperf::navtiming':
        kafka_brokers => $kafka_brokers,
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
    }
}
