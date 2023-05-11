class role::pontoon::lb {
    system::role { 'pontoon::lb':
        description => 'Pontoon Load Balancer',
    }

    include ::profile::base::production
    include ::profile::firewall

    include ::profile::pontoon::lb
}
