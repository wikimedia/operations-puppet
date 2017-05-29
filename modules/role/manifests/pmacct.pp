class role::pmacct {
    system::role { 'role::pmacct':
        description => 'pmacct netflow accounting',
    }

    $kafka_config  = kafka_config('analytics')
    class { '::pmacct':
        kafka_brokers => $kafka_config['brokers']['string'],
    }

    include ::standard
    include ::base::firewall

    ferm::service { 'bgp':
        proto  => 'tcp',
        port   => '179',
        desc   => 'BGP',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'netflow':
        proto  => 'udp',
        port   => '2100',
        desc   => 'NetFlow',
        srange => '$PRODUCTION_NETWORKS',
    }
}
