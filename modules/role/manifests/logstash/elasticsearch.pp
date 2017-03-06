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
    # Elasticsearch 5 doesn't allow setting the plugin path, we need
    # to symlink it into place. The directory already exists as part of the
    # debian package, so we need to force the creation of the symlink.
    file { '/usr/share/elasticsearch/plugins':
      ensure  => 'link',
      target  => '/srv/deployment/elasticsearch/plugins/',
      force   => true,
      require => Package['elasticsearch/plugins'],
    }

    class { '::elasticsearch':
      require => [
          Package['elasticsearch/plugins'],
          File['/usr/share/elasticsearch/plugins'],
      ],
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
