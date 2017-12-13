# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include ::standard
    include ::elasticsearch::monitor::diamond
    include ::profile::elasticsearch::monitoring
    include ::profile::base::firewall

    # the logstash cluster has 3 data nodes, and each shard has 3 replica (each
    #shard is present on each node). If one node is lost, 1/3 of the shards
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
    }

    apt::repository { 'wikimedia-elastic':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'component/elastic55 thirdparty/elastic55',
        before     => Class['::elasticsearch'],
    }

    class { '::elasticsearch':
        require                    => File['/usr/share/elasticsearch/plugins'],
        curator_uses_unicast_hosts => false, # elasticsearch API is only exposed to localhost
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
