class role::requesttracker_server {

    include ::standard
    include ::profile::requesttracker::server
    interface::add_ip6_mapped { 'main': }

}
