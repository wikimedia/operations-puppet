class role::maps::labs::postgres_slave {
    include ::standard
    include ::base::firewall

    include ::profile::maps::osm_slave

    system::role { 'maps::postgres_slave':
        ensure      => 'present',
        description => 'Maps postgres slave',
    }

}
