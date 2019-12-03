# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::collector7
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $prometheus_nodes: List of prometheus nodes to allow connections from
#
# filtertags: labs-project-deployment-prep
class role::logstash::collector7 (
    $prometheus_nodes = hiera('prometheus_nodes', []), # lint:ignore:wmf_styleguide
) {
    system::role { 'logstash::collector7':
      description => 'Logstash 7 log collector and indexer',
    }

    class { '::profile::logstash::collector7':
        prometheus_nodes => $prometheus_nodes,
    }

    include ::role::logstash::elasticsearch
    include ::profile::base::firewall

}
