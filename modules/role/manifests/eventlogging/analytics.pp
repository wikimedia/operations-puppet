class role::eventlogging::analytics {
    system::role { 'eventlogging_host':
        description => 'eventlogging host'
    }
    include ::standard
    include ::base::firewall
    interface::add_ip6_mapped { 'main': }
    include ::role::eventlogging::analytics::processor
    include ::role::eventlogging::analytics::mysql
    include ::role::eventlogging::analytics::files

    # Temporary hack to allow a easier deployment/migration to eventlog1002
    # T114199
    if $::hostname == 'eventlog1001' {
        include ::role::eventlogging::analytics::zeromq
    }
}
