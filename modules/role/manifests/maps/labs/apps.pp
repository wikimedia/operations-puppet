class role::maps::labs::apps {
    include ::standard
    include ::base::firewall

    include ::profile::maps::apps

    system::role { 'maps::apps':
        ensure      => 'present',
        description => 'Maps apps (tilerator, kartotherian)',
    }
}
