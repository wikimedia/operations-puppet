class role::maps::labs::cassandra {
    include ::standard
    include ::base::firewall

    include ::profile::maps::cassandra

    system::role { 'maps::cassandra':
        ensure      => 'present',
        description => 'Maps cassandra',
    }
}
