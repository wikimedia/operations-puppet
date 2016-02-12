class role::pmacct {
    system::role { 'role::pmacct':
        description => 'pmacct netflow accounting',
    }

    include ::pmacct

    ferm::service { 'bgp':
        proto  => 'tcp',
        port   => '179',
        desc   => 'BGP',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'netflow':
        proto  => 'udp',
        port   => '2100',
        desc   => 'NetFlow',
        srange => '$ALL_NETWORKS',
    }
}
