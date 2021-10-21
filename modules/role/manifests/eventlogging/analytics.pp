class role::eventlogging::analytics {
    system::role { 'eventlogging_host':
        description => 'eventlogging host'
    }
    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::eventlogging::analytics::processor
}
