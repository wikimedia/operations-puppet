# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include ::standard
    include ::elasticsearch::monitor::diamond
    include ::base::firewall

    # the logstash cluster has 3 data nodes, and each shard has 3 replica (each
    #shard is present on each node). If one node is lost, 1/3 of the shards
    # will be unassigned, with no way to reallocate them on another node, which
    # is fine and should not raise an alert. So threshold needs to be > 1/3.
    class { '::elasticsearch::nagios::check':
        threshold => '34',
    }

    if $::standard::has_ganglia {
        include ::elasticsearch::ganglia
    }

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }
    # Elasticsearch 5 doesn't allow setting the plugin path, we need
    # to symlink it into place. The directory already exists as part of the
    # debian package, so we need to force the creation of the symlink.
    $plugins_dir = '/srv/deployment/elasticsearch/plugins'
    file { '/usr/share/elasticsearch/plugins':
      ensure  => 'link',
      target  => $plugins_dir,
      force   => true,
      require => Package['elasticsearch/plugins'],
    }

    class { '::elasticsearch':
      require     => [
          Package['elasticsearch/plugins'],
          File['/usr/share/elasticsearch/plugins'],
      ],
      plugins_dir => $plugins_dir,
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
