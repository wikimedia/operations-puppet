class role::eventlogging::analytics {
    system::role { 'eventlogging_host':
        description => 'eventlogging host'
    }
    include ::standard
    include ::base::firewall
    interface::add_ip6_mapped { 'main': }
    include ::role::eventlogging::analytics::zeromq
    include ::role::eventlogging::analytics::processor
    include ::role::eventlogging::analytics::mysql
    include ::role::eventlogging::analytics::files
    include ::role::logging::mediawiki::errors
}
