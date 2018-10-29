class role::wmcs::toolforge::services {
    system::role { $name: }
    # not sure about the next two
    #include ::standard
    #include ::profile::base::firewall
    include ::profile::toolforge::grid::base
    include ::profile::toolforge::services::basic
    include ::profile::toolforge::services::aptly
    include ::profile::toolforge::services::bigbrother
    include ::profile::toolforge::services::updatetools
}
