class role::cache::text {
    include profile::base::production
    include profile::cache::base
    include profile::tcp_fast_open
    include profile::cache::haproxy
    include profile::cache::varnish::frontend
    include profile::prometheus::varnish_exporter
    include profile::cache::varnish::frontend::text
    include profile::trafficserver::backend
    include profile::lvs::realserver::ipip

    # varnishkafka statsv listens for special stats related requests
    # and sends them to the 'statsv' topic in Kafka. A kafka consumer
    # (called 'statsv') then consumes these and emits metrics.
    include profile::cache::kafka::statsv

    include profile::cache::haproxykafka
}
