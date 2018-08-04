class role::eventlogging::analytics {
    system::role { 'eventlogging_host':
        description => 'eventlogging host'
    }
    include ::standard
    include ::profile::base::firewall

    include ::role::eventlogging::analytics::processor
    include ::role::eventlogging::analytics::mysql
    include ::role::eventlogging::analytics::files
}
