# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logging::opensearch::collector
#
# Provisions Collector node for a Logstash cluster.
#
class role::logging::opensearch::collector {
    include profile::base::production
    include profile::firewall
    include profile::opensearch::logstash
    include profile::opensearch::monitoring::base_checks
    include profile::opensearch::dashboards
    include profile::opensearch::dashboards::httpd_proxy
    include profile::opensearch::dashboards::phatality
    include profile::prometheus::logstash_exporter
    include profile::benthos

    # https://phabricator.wikimedia.org/T327161
    include toil::opensearch_dashboards_restart # lint:ignore:wmf_styleguide

    if $::realm == 'production' {
        include profile::logstash::production
        include profile::tlsproxy::envoy # TLS termination
        include profile::lvs::realserver
        include profile::opensearch::api::httpd_proxy
    } else {
        include profile::logstash::beta
    }

    include profile::jaeger::scripts
}
