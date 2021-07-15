class role::pontoon::lb {
    system::role { 'pontoon::lb':
        description => 'Pontoon Load Balancer',
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::pontoon::lb
}
