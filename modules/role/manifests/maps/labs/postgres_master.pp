class role::maps::labs::postgres_master {
    include ::standard
    include ::base::firewall

    include ::profile::maps::osm_master
    include ::profile::redis::master

    system::role { 'maps::postgres_master':
        ensure      => 'present',
        description => 'Maps postgres master',
    }

}
