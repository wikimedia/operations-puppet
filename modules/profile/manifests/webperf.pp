class profile::webperf(
    $statsd = hiera('statsd')
){
    $statsd_parts = split($statsd, ':')
    $statsd_host = $statsd_parts[0]
    $statsd_port = $statsd_parts[1]

    # statsv is on main kafka, not analytics or jumbo kafka.
    # Note that at any given time, all statsv varnishkafka producers are
    # configured to send to only one kafka cluster (usually main-eqiad).
    # statsv in an inactive datacenter will not process any messages, as
    # varnishkafka will not produce any messages to that DC's kafka cluster.
    # This is configured by the value of the hiera param
    # profile::cache::kafka::statsv::kafka_cluster_name when the statsv varnishkafka
    # profile is included (as of this writing on text caches).
    $kafka_main_config = kafka_config('main')
    $kafka_main_brokers = $kafka_main_config['brokers']['string']
    # Consume statsd metrics from Kafka and emit them to statsd.
    class { '::webperf::statsv':
        kafka_brokers => $kafka_main_brokers,
        statsd        => $statsd,
    }

    # Use brokers from this Kafka cluster to consume metrics.
    $kafka_config  = kafka_config('jumbo-eqiad')
    $kafka_brokers = $kafka_config['brokers']['string']

    # Aggregate client-side latency measurements collected via the
    # NavigationTiming MediaWiki extension and send them to Graphite.
    # See <https://www.mediawiki.org/wiki/Extension:NavigationTiming>
    class { '::webperf::navtiming':
        kafka_brokers => $kafka_brokers,
        statsd_host   => $statsd_host,
        statsd_port   => $statsd_port,
    }

    # Make a valid target for coal, and set up what's needed for the consumer
    # Consumes from the jumbo-eqiad cluster, just like navtiming
    class { '::coal::processor':
        kafka_brokers => $kafka_brokers
    }

    class { '::coal::web': }
}
