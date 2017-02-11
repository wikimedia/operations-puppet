# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include ::standard
    include ::elasticsearch::nagios::check
    include ::elasticsearch::monitor::diamond
    include ::base::firewall

    if $::standard::has_ganglia {
        include ::elasticsearch::ganglia
    }

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require      => Package['elasticsearch/plugins'],
    }

    $logstash_nodes = hiera('logstash::cluster_hosts')
    $logstash_nodes_ferm = join($logstash_nodes, ' ')

    ferm::service { 'logstash_elastic_internode':
        proto   => 'tcp',
        port    => 9300,
        notrack => true,
        srange  => "@resolve((${logstash_nodes_ferm}))",
    }
}
