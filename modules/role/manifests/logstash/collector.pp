# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::collector
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $prometheus_nodes: List of prometheus nodes to allow connections from
#
# filtertags: labs-project-deployment-prep
class role::logstash::collector (
    $prometheus_nodes = hiera('prometheus_nodes', []), # lint:ignore:wmf_styleguide
) {
    system::role { 'logstash::collector':
      description => 'Logstash log collector and indexer',
    }

    class { '::profile::logstash::collector':
        prometheus_nodes => $prometheus_nodes,
    }

    include ::role::logstash::elasticsearch
    include ::profile::base::firewall

}
