class role::cache::upload {
    include profile::base::production
    include profile::netconsole::client

    include profile::cache::base
    include profile::cache::haproxy
    include profile::cache::varnish::frontend
    include profile::prometheus::varnish_exporter
    include profile::trafficserver::backend
    include profile::lvs::realserver::ipip
    include profile::cache::haproxykafka
}
