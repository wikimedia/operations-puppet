# == Class: role::webperf
#
# This role provisions a set of front-end monitoring tools that feed
# into StatsD.
#
class role::webperf {

    include ::standard
    include ::base::firewall

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

    # TODO: Remove eventlogging specific things once ve uses Kafka: T110903
    include ::eventlogging
    $eventlogging_host = 'eventlog1001.eqiad.wmnet'
    # Installed by eventlogging class using trebuchet
    $eventlogging_path = '/srv/deployment/eventlogging/eventlogging'
    # Report VisualEditor performance measurements to Graphite.
    # See <https://meta.wikimedia.org/wiki/Schema:TimingData>
    class { '::webperf::ve':
        endpoint          => "tcp://${eventlogging_host}:8600",
        eventlogging_path => $eventlogging_path,
        statsd_host       => $statsd_host,
        statsd_port       => $statsd_port,
    }
}
