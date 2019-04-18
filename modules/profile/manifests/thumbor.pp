class profile::thumbor(
    $memcached_servers_nutcracker = hiera('thumbor_memcached_servers_nutcracker'),
    $logstash_host = hiera('logstash_host'),
    $logstash_port = hiera('logstash_logback_port'),
    $swift_sharded_containers = hiera_array('swift::proxy::shard_container_list'),
    $swift_private_containers = hiera_array('swift::proxy::private_container_list'),
    $thumbor_mediawiki_shared_secret = hiera('thumbor::mediawiki::shared_secret'),
    $prometheus_nodes         = hiera('prometheus_nodes', []),
    $statsd_port = hiera('statsd_exporter_port'),
) {
    include ::profile::conftool::client
    class { 'conftool::scripts': }

    class { '::thumbor::nutcracker':
        thumbor_memcached_servers => $memcached_servers_nutcracker,
    }

    class { '::thumbor':
        logstash_host => $logstash_host,
        logstash_port => $logstash_port,
        statsd_port   => $statsd_port,
    }

    include ::swift::params
    $swift_account_keys = $::swift::params::account_keys

    class { '::thumbor::swift':
        swift_key                       => $swift_account_keys['mw_thumbor'],
        swift_private_key               => $swift_account_keys['mw_thumbor-private'],
        swift_sharded_containers        => $swift_sharded_containers,
        swift_private_containers        => $swift_private_containers,
        thumbor_mediawiki_shared_secret => $thumbor_mediawiki_shared_secret,
    }

    ferm::service { 'thumbor':
        proto  => 'tcp',
        port   => '8800',
        srange => '$DOMAIN_NETWORKS',
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    ferm::service { 'mtail':
      proto  => 'tcp',
      port   => '3903',
      srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
