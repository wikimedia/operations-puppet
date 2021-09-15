# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logging::opensearch::data
#
# Provisions OpenSearch backend node for a Logstash cluster.
#
class role::logging::opensearch::data {
    system::role { 'logging::opensearch::data':
      description => 'OpenSearch Data Node',
    }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::opensearch::logstash
    include ::profile::opensearch::monitoring::base_checks
}
