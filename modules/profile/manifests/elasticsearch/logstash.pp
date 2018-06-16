# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class profile::elasticsearch::logstash(
    Wmflib::IpPort $http_port = hiera('profile::elasticsearch::http_port'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
) {
    include ::profile::elasticsearch

    # the logstash cluster has 3 data nodes, and each shard has 3 replica (each
    # shard is present on each node). If one node is lost, 1/3 of the shards
    # will be unassigned, with no way to reallocate them on another node, which
    # is fine and should not raise an alert. So threshold needs to be > 1/3.
    class { '::elasticsearch::nagios::check':
        threshold => '>=0.34',
    }

    file { '/usr/share/elasticsearch/plugins':
        ensure => 'directory',
        force  => true,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    } -> Class['elasticsearch']

    profile::prometheus::elasticsearch_exporter { "${::hostname}:${http_port}":
        prometheus_nodes   => $prometheus_nodes,
        prometheus_port    => 9108,
        elasticsearch_port => $http_port,
    }
}
