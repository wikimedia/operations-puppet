# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logging::opensearch::collector
#
# Provisions Collector node for a Logstash cluster.
#
class role::logging::opensearch::collector {
    system::role { 'logging::opensearch::collector':
        description => 'Logstash, OpenSearch non-data node, and OpenSearch Dashboards host',
    }

    include profile::base::production
    include profile::base::firewall
    include profile::opensearch::logstash
    include profile::opensearch::monitoring::base_checks
    include profile::opensearch::dashboards
    include profile::opensearch::dashboards::httpd_proxy
    include profile::prometheus::logstash_exporter

    if $::realm == 'production' {
        include profile::logstash::production
        include profile::tlsproxy::envoy # TLS termination
        include profile::lvs::realserver
    } else {
        include profile::logstash::beta
    }
}
