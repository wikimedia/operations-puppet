class role::pmacct {
    system::role { 'role::pmacct':
        description => 'pmacct netflow accounting',
    }

    include ::pmacct
    include ::base::firewall
    include ::standard

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
