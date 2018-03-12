class role::eventlogging::analytics::legacy {
    system::role { 'eventlogging_host':
        description => 'eventlogging host'
    }
    include ::standard
    include ::base::firewall
    interface::add_ip6_mapped { 'main': }

    include ::role::eventlogging::analytics::zeromq
}
