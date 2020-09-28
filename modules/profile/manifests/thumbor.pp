class profile::thumbor(
    Array[String] $memcached_servers_nutcracker = lookup('thumbor_memcached_servers_nutcracker'),
    Stdlib::Port $logstash_port = lookup('logstash_logback_port'),
    Array[String] $swift_sharded_containers = lookup('profile::swift::proxy::shard_container_list', {'merge' => 'unique'}),
    Array[String] $swift_private_containers = lookup('profile::swift::proxy::private_container_list', {'merge' => 'unique'}),
    String $thumbor_mediawiki_shared_secret = lookup('thumbor::mediawiki::shared_secret'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {'default_value' => []}),
    Stdlib::Port $statsd_port = lookup('statsd_exporter_port'),
    Hash $swift_account_keys = lookup('profile::swift::accounts_keys'),
){

    include ::profile::conftool::client
    class { 'conftool::scripts': }

    class { '::thumbor::nutcracker':
        thumbor_memcached_servers => $memcached_servers_nutcracker,
    }

    # rsyslog forwards json messages sent to localhost along to logstash via kafka
    class { '::profile::rsyslog::udp_json_logback_compat':
        port => $logstash_port,
    }

    class { '::thumbor':
        logstash_host => 'localhost',
        logstash_port => $logstash_port,
        statsd_port   => $statsd_port,
    }

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
