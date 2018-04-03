class role::installserver {
    system::role { 'installserver': }

    include ::standard
    include ::profile::base::firewall
    include ::profile::backup::host

    include ::profile::installserver::tftp
    include ::role::installserver::dhcp
    include ::role::installserver::http
    include ::role::installserver::proxy
    include ::role::installserver::preseed
    include ::role::aptrepo::wikimedia

    interface::add_ip6_mapped { 'main': }

}
